#!/bin/bash

##########################################
# WS-Discoberyサービス起動スクリプト
#
# 注意: 自分でntpdをソースでビルドした場合は
#       /lib/systemd/system-preset/90-systemd.presetの
#       enable systemd-timesyncd.service
#       の行を
#       disable systemd-timesyncd.service
#       に変更する。
#       理由は不明。
#
# 引数
# $1    start       起動
#       stop        停止
#       restart     再起動
#       help        使い方
#
# 終了ステータス
#   0   通常終了
#   1   起動や停止が失敗
#   2   引数エラー
#   4   インターネットに接続していない

# 環境変数設定ファイルとその読み込み
WSDDSRC=/usr/local/sh/sysconfig/wsdd
if [[ -r $WSDDSRC ]]
then
    source "$WSDDSRC"
fi
# help文字列 
USAGE_STRING="usage: wsdd.sh [start | reload | stop | start]"


if [ -r /usr/local/sh/init.d/initrc ]; then
    . /usr/local/sh/init.d/initrc
fi

##
# 起動前にサーバープログラムの存在確認、オプション処理を実行する。
function _preexec() {
    # サーバープログラムが存在するか
    if [[ ! -x $server ]]
    then
        echo "WS-Discovery Deamon wsddが存在しません。" 1>&2
        echo "$USAGE_STRING" 1>&2
        return -1
    fi
    # オプション処理
    OPTS=""
    if [[ -n $DOMAIN ]]
    then
        OPTS=" -d $DOMAIN "
    else
        if [[ -n $WORKGROUP ]]
        then
            OPTS=" -w $WORKGROUP "
        fi
    fi
    if [[ -n $HOSTNM ]]
    then
        OPTS="$OPTS -n $HOSTNM"
    fi
    return 0
}

# 起動
_start() {
    _preexec || return -1
    if get_prog_pid $server
    then
        echo "WS-Discovery wsdd[$server]は既に起動しています" 1>&2
        echo "$USAGE_STRING" 1>&2
        return -2
    fi
    $server $OPTS &
    if (( $? != 0 ))
    then
        echo "WS-Discovery wsdd 起動失敗 $server" 1>&2
    fi
    return 0;
}
#停止
_stop() {
    local pid
    pid=$(get_prog_pid $server)
    if [[ -z $pid ]]
    then
        echo "WS-Discovery wsdd[$server]は起動していません。" 1>&2
        echo "$USAGE_STRING" 1>&2
        return -1
    fi
    kill -15 $pid
    if (( $? != 0 ))
    then
        echo "WS-Discovery wsdd[$server]の停止失敗" 2>&1
        echo "$USAGE_STRING" 1>&2
        return -2
    fi
    return 0;
}

ret=0
case $1 in
    start)
        _start
        ret=$?
        ;;
    stop)
        _stop
        ret=$?
        ;;
    restart)
        _stop
        sleep 1
        _start
        ret=$?
        ;;
    help)
        echo $USAGE_STRING
        ret=0
        ;;
    *)
        echo "Error invalid arguments $1" 1>&2
        echo "$USAGE_STRING" 1>&2
        ret="-10"
        ;;
esac


exit $ret


