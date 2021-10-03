#!/bin/bash

# マウントポイントのディレクトリを作成
mp_list="/usr/local/etc/samba/mp.txt"
if [[ -r ${mp_list} ]]
then
    /usr/local/sh/system/mp.sh ${mp_list}
fi

# ログインユーザーとsambaユーザーの作成
users_list="/usr/local/etc/samba/users_list.txt"
if [[ -r ${users_list} ]]
then
    /usr/local/sh/system/user_add.sh ${users_list}
fi

# pdbeditのパスワードファイルの設定
SAMBA_TDB_DIR=${SAMBA_HOME}/var/lib/samba/private
# SAMBA_TDB_FILE=${TDB_DIR}/passdb.tdb
TDB_DIR="/usr/local/etc/samba/private"
if [[ -d ${TDB_DIR} ]]
then
    cp -rf ${TDB_DIR} ${SAMBA_TDB_DIR}
fi

# wsddの環境変数設定ファイルの配置
# デフォルトの環境変数は/usr/local/sh/default_sysconfig/wsddである。
# wsddの環境変数ファイルはdocker-composeで環境変数で渡すことができ
# 環境変数名はWSDDSRCである。もし渡っていなければデフォルトの環境変数設定ファイルが使用される。
if [[ -n ${WSDDSRC} && -r ${WSDDSRC} ]]
then
    cp ${WSDDSRC} /usr/local/sh/sysconfig
else
    cp /usr/local/sh/default_sysconfig/wsdd /usr/local/sh/sysconfig
fi

sleep 2
systemctl daemon-reload
systemctl enable smbd
systemctl enable nmbd
systemctl enable wsdd
systemctl start smbd
systemctl start nmbd
systemctl start wsdd

exit 0

