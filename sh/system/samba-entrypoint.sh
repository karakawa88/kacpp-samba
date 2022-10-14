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

exec /bin/systemd

