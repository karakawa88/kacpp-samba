# Python開発環境を持つdebianイメージ
# 日本語化も設定済み
FROM        kagalpandh/kacpp-pydev AS builder
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
ENV         DEBIAN_FORONTEND=noninteractive
# https://download.samba.org/pub/samba/stable/samba-4.14.5.tar.gz
ENV         SAMBA_VERSION=4.14.6
ENV         SAMBA_DEST=samba-${SAMBA_VERSION}
ENV         SAMBA_SRC_FILE=${SAMBA_DEST}.tar.gz
ENV         SAMBA_URL="https://download.samba.org/pub/samba/${SAMBA_SRC_FILE}"
ENV         SAMBA_HOME=/usr/local/${SAMBA_DEST}
COPY        sh/apt-install/  /usr/local/sh/apt-install
RUN         mkdir -p /usr/local/sh/pip3
COPY        sh/pip3/        /usr/local/sh/pip3
# 開発環境インストール
RUN         apt update && \
#             /usr/local/sh/system/apt-install.sh install gccdev.txt && \
                /usr/local/sh/system/apt-install.sh install samba-dev.txt && \
                pip3 install $(cat /usr/local/sh/pip3/samba-pip3.txt | xargs)
RUN         wget ${SAMBA_URL} && tar -zxvf ${SAMBA_SRC_FILE} && cd ${SAMBA_DEST} && \
                ./configure --prefix=/usr/local/${SAMBA_DEST} --enable-fhs && \
                make && make install && \
                apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*
FROM        kagalpandh/kacpp-pydev
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
ENV         SAMBA_VERSION=4.14.6
ENV         SAMBA_DEST=samba-${SAMBA_VERSION}
ENV         SAMBA_HOME=/usr/local/samba
ENV         PATH=${SAMBA_HOME}/bin:${SAMBA_HOME}/sbin:$PATH
COPY        --from=builder /usr/local/${SAMBA_DEST}/ /usr/local/${SAMBA_DEST}
COPY        sh/apt-install/samba-dev.txt /usr/local/sh/apt-install
COPY        etc/systemd/system/  /etc/systemd/system
COPY        sh/system/  /usr/local/sh/system
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
            mkdir /var/log/samba && chown root.admin /var/log/samba && chmod 3770 /var/log/samba && \
            # systemd
            apt install -y systemd && \
            chown root /usr/local/sh/system/*.sh && chmod 775 /usr/local/sh/system/*.sh && \
            cd ~/ && apt clean && rm -rf /var/lib/apt/lists/*
ENTRYPOINT  ["/usr/local/sh/system/samba-entrypoint.sh"]
