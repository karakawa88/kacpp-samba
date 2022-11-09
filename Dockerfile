# Python開発環境を持つdebianイメージ
# 日本語化も設定済み
FROM        kagalpandh/kacpp-pydev AS builder
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
ENV         DEBIAN_FORONTEND=noninteractive
# https://download.samba.org/pub/samba/stable/samba-4.14.5.tar.gz
ENV         SAMBA_VERSION=4.17.0
ENV         SAMBA_DEST=samba-${SAMBA_VERSION}
ENV         SAMBA_SRC_FILE=${SAMBA_DEST}.tar.gz
ENV         SAMBA_URL="https://download.samba.org/pub/samba/"
ENV         SAMBA_GPG_PUBKEY="samba-pubkey.asc"
ENV         SAMBA_GPG_PUBKEY_URL="https://download.samba.org/pub/samba/${SAMBA_GPG_PUBKEY}"
ENV         SAMBA_HOME=/usr/local/${SAMBA_DEST}
COPY        sh/apt-install/  /usr/local/sh/apt-install
RUN         mkdir -p /usr/local/sh/pip3
COPY        sh/pip3/        /usr/local/sh/pip3
# 開発環境インストール
RUN         apt update && \
            /usr/local/sh/system/apt-install.sh install gccdev.txt && \
                /usr/local/sh/system/apt-install.sh install samba-dev.txt && \
                pip3 install $(cat /usr/local/sh/pip3/samba-pip3.txt | xargs)
RUN         wget ${SAMBA_URL}/${SAMBA_SRC_FILE} && wget ${SAMBA_URL}/${SAMBA_DEST}.tar.asc && \
#           GPG verify
            wget ${SAMBA_GPG_PUBKEY_URL} && \
                gpg --import ${SAMBA_GPG_PUBKEY} && \
                gunzip ${SAMBA_SRC_FILE} && \
                gpg ${SAMBA_DEST}.tar.asc && \
#           samba build
            tar -xvf ${SAMBA_DEST}.tar && cd ${SAMBA_DEST} && \
                ./configure --prefix=/usr/local/${SAMBA_DEST} --enable-fhs && \
                make && make install && \
                apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*
FROM        kagalpandh/kacpp-pydev
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
ENV         SAMBA_VERSION=4.17.0
ENV         SAMBA_DEST=samba-${SAMBA_VERSION}
ENV         SAMBA_HOME=/usr/local/samba
ENV         PATH=${SAMBA_HOME}/bin:${SAMBA_HOME}/sbin:$PATH
COPY        --from=builder  /usr/local/${SAMBA_DEST}/ /usr/local/${SAMBA_DEST}
COPY        sh/apt-install/samba-dev.txt /usr/local/sh/apt-install
RUN         mkdir -p /usr/local/sh/pip3
COPY        sh/pip3/        /usr/local/sh/pip3
RUN         apt update && \
            /usr/local/sh/system/apt-install.sh install samba-dev.txt && \
            pip3 install $(cat /usr/local/sh/pip3/samba-pip3.txt | xargs)
RUN         ln -s /usr/local/${SAMBA_DEST} /usr/local/samba && \
            # pdbeditに-sで設定ファイルを指定しても有効にできなかったので
            # /usr/local/samba内のetcのsmb.confにリンク設定
            ln -s /usr/local/etc/samba/smb.conf /usr/local/${SAMBA_DEST}/etc/samba/smb.conf && \
            echo "/usr/local/samba/lib/samba" >>/etc/ld.so.conf && \
            ldconfig && \
            mkdir /var/log/samba && chown root /var/log/samba && chmod 3770 /var/log/samba && \
            mkdir /home/samba_users && chown root /home/samba_users && \
                chmod 3775 /home/samba_users
COPY        sh/init.d/ /usr/local/sh/init.d
# WSDサーバー wsddのインストールと環境構築
RUN         mkdir /usr/local/sh/default_sysconfig && mkdir /usr/local/sh/sysconfig && \
            chmod 3750 /usr/local/sh/default_sysconfig && chmod 3750 /usr/local/sh/sysconfig
COPY        sh/default_sysconfig/   /usr/local/sh/default_sysconfig
RUN         git clone --depth 1 'https://github.com/christgau/wsdd.git' && \
            cp wsdd/src/wsdd.py /usr/local/sbin && \
            chmod 755 /usr/local/sbin/wsdd.py && \
            chmod 755 /usr/local/sh/init.d/wsdd.sh
COPY        etc/systemd/system/  /etc/systemd/system
COPY        sh/system/  /usr/local/sh/system
            # systemd
ENV container docker
#VOLUME [ "/sys/fs/cgroup" ]
# systemdのインストールと設定
RUN         apt install -y systemd && \
            chown root /usr/local/sh/system/*.sh && chmod 775 /usr/local/sh/system/*.sh && \
            # メールサーバーexim4が何故かインストールされるのでアンインストール
            apt remove --purge exim-base && \
            (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
            systemd-tmpfiles-setup.service ] || rm -f $i; done); \
            rm -f /lib/systemd/system/multi-user.target.wants/*;\
            rm -f /etc/systemd/system/*.wants/*;\
            rm -f /lib/systemd/system/local-fs.target.wants/*; \
            rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
            rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
            rm -f /lib/systemd/system/basic.target.wants/*;\
            rm -f /lib/systemd/system/anaconda.target.wants/* && \
            cd ~/ && apt clean && rm -rf /var/lib/apt/lists/*
# cronとlogrotateの設定
COPY        etc/cron.d/     /etc/cron.d
COPY        etc/logrotate.d/     /etc/logrotate.d
ENTRYPOINT  ["/usr/local/sh/system/samba-entrypoint.sh"]
