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

sleep 2
systemctl daemon-reload
systemctl enable smbd
systemctl enable nmbd
systemctl enable wsdd
systemctl start smbd
systemctl start nmbd
systemctl start wsdd

exit 0

