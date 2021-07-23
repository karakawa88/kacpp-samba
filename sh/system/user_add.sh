#!/bin/bash

function is_user() {
    if cat /etc/passwd | awk -F":" '{print $1}' | grep -q "$1"
    then
        return 0
    else
        return 1
    fi
}
function is_group() {
    if cat /etc/group | awk -F":" '{print $1}' | grep -q "$1"
    then
        return 0
    else
        return 1
    fi
}
function is_samba_user() {
    if pdbedit -L  | awk -F":" '{print $1}' | grep -q "$1"
    then
        return 0
    else
        return 1
    fi
}

shell="/bin/sh"
samba_conf="/usr/local/etc/samba/smb.conf"
if [[ $# -le 0 ]]
then
    users_list="users_list.txt"
else
    users_list=$1
fi

cat ${users_list} | grep -E -v '(^[ \t]*$)|(^#.*)' |\
while read line
do
    str=$(echo $line | sed -r 's/:/ /g')
    read user user_id user_password group group_id samba_user samba_password<<<$str
    echo "user=$user, user_id=${user_id}, passwd=${user_password}, group=${group}, group_id=${group_id}"
    echo "samba_user=${samba_user}, samba_password=${samba_password}"
    # グループ追加
    if ! is_group ${group}
    then
        groupadd -g ${group_id} ${group}
    fi
    # ユーザー追加
    home_dir="/home/${user}"
    if ! is_user ${user}
    then
        useradd -m -d ${home_dir} -s ${shell} -g ${group} -G ${group} -u ${user_id} ${user}
        echo ${user_password} | passwd --stdin ${user}
    fi
    # sambaユーザー追加
    if ! is_samba_user ${samba_user}
    then
        echo "${samba_password}\n${samba_password}" | pdbedit -s ${samba_conf} -a ${samba_user} -t
    fi

done



