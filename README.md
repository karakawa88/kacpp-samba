# kacpp-samba Sambaサーバーイメージ

## 概要
SambaサーバーをソースからインストールしてSambaを起動実行するイメージ。

## バージョン
Sambaのバージョンは4.14.17です。

## 使い方
```shell
# Dockerでの使い方
docker image pull kagalpandh/kacpp-samba
docker run -dit --name kacpp-samba kagalpandh/kacpp-samba
# sambaが起動しているコンテナーに一旦入る
docker exec -it kacpp-samba "/bin/bash"
# Sambaサーバーの初期化スクリプト実行
/usr/local/sh/system/samba-init.sh
# Sambaユーザー追加
pdbedit -a -u ユーザー名
....
```

## 説明
Sambaをソースからインストールしてある。
Sambaのホームは/usr/local/sambaである。
Sambaのサーバーはsmbdとnmbdと複数あるためsystemdで起動する。
それぞれ名前はsmbd.serviceとnmbd.serviceである。
systemdはDockerfileで自動起動が登録されないため初期化スクリプト
/usr/local/sh/system/samba-init.shを実行する必要がある。
Sambaの設定は/usr/local/etc/sambaに設定ファイル群があるものと仮定している。
ユーザーはpdbedit形式を使用するようにしてある。
ユーザーは追加されておらず追加する場合はまず設定ファイルのある/usr/local/etc/sambaにusers_list.txtを作成。
そのファイルにOSユーザーとSambaユーザーを記述する。
users_list.txtの書式
ユーザー名:ユーザーID:パスワード:グループ名:グループID:Sambaユーザー名:Sambaユーザーのパスワード
しかしここではSambaのユーザーとパスワードは使われない。
しかしこれだけではSambaユーザーは作成されない。
Sambaユーザーを作成するには以下のようにする必要がある。
```shell
docker exec -it kacpp-samba "/bin/bash"
# Sambaユーザー追加
pdbedit -a -u ユーザー名
....
```
# Sambaユーザーが自動で作成されない理由
pdbeditでパスワードを入力する必要がありしかも標準入力でパスワードを渡せないため。
後日修正される可能性あり。

# Sambaのマウントポイント
Sambaの設定ファイルディレクトリは/usr/local/etc/sambaと決まっており
Sambaの挙動を変えたい場合はここにvolumeをマウントする必要がある。
独自のマウントポイントでvolumeをmountする場合はコンテナーに入り自分で作成するか
起動時に作成するようにmp.txtをsmb.confと同じディレクトリに配置する。
mp.txtの書式はただ作成したいマウントポイントのディレクトリ名を一行づつ記したファイルである。

# ログ
ログは/var/log/samba/samba.logにあるものとしてある。
そしてそのログにはlogrotateの設定がされてありcronに登録されてある。

## WSD
SambaはWSDに今のところ対応していないためwsddを入れてWSDに対応することにした。
初期化スクリプトsamba-init.shで自動起動できるようになる。
wsddはオプションで-d DOMAINでドメイン名または-w ワークグループ名と-n ホスト名で指定する必要がある。
これは環境変数ファイル/usr/local/sh/sysconfig/wsddで設定する。
このファイルは起動時に読み込ませることができdocker-composeやdocker起動時の環境変数で
WSDDSRCで指定できる。大抵はマウントしたsambaの設定ファイルがあるディレクトリに配置するようにする。
自分でwsddのオプションを指定するには必ずこの環境変数にファイルのパスを指定する。
#wsdd環境変数設定ファイル書式
```shell
##
# WS-Discoveryサービス起動スクリプト環境変数設定ファイル
# ファイル名: wsdd
# 環境変数
# server    サーバープログラムのパス
# server_opts   その他にwsddに渡すオプション
#   -H LIMIT        最大ホップ数
#   --ipv4only      ipv4のみ
#   -d              ドメイン名(環境変数で設定)
#   -w              ワークグループ名(環境変数で設定)
#   -n              ホスト名名(環境変数で設定)
#                   NetBIOSのホスト名
# DOMAIN    ドメイン名
# WORKGROUP WORKGROUP名
# HOSTNM    ホスト名
# ドメイン名を設定したらWORKGROUP名とHOSTNMはいらないし、
# WORKGROUP名とHOSTNMを設定したらDOMAIN名はいらない。
server="/usr/local/sbin/wsdd.py"
server_opts=" --ipv4only -H 20 "
DOMAIN=""
WORKGROUP="KARASPSMB"
HOSTNM="KARASPSMBFS"
```
#docker-composeでの使用
```shell
version: "3"

services:
    ....
    kacpp-samba:
        network_mode: host
        expose:
            - "137"
            - "138"
            - "139"
            - "445"
            - "5357"
            - "5358"
            - "3702"
       ....
       ....
       env_file: kacpp-samba.src
```
wsddはそのホストのネットワーク情報を必要とする。
dockerで起動する場合は仮想に独自のネットワークを作成しそこにポートフォワーディングをして送受信している。
これだとこのdockerのネットワークでwsddを立ち上げるとその中のネットワークの情報がWSDで送信されるため
コンピューターが表示されないという問題がある。
そのためネットワークはホストのネットワークを使用するためnetwork_mode: hostを指定している。
その他使用するポート番号をexposeで指定している。注意するのはexposeの場合はポート番号のみ指定可能で
tcpやudp指定はできない。(/tcpや/udp)
これはdockerで起動する時も同じである。

##構成
Sambaホーム         /usr/local/samba
設定ディレクトリ    /usr/local/etc/samba
    設定ファイル        smb.conf
    ユーザーのwsdd環境変数設定ファイル   wsdd
システムスクリプト  /usr/local/sh/system
wsddの設定ファイル  /usr/local/sh/sysconfig/wsdd
サービス起動スクリプト  /usr/local/sh/wsdd.sh
ログ                /var/log/samba.log

##ベースイメージ
kagalpandh/kacpp-pydev

# その他
DockerHub: [kagalpandh/kacpp-samba](https://hub.docker.com/repository/docker/kagalpandh/kacpp-samba)<br />
GitHub: [karakawa88/kacpp-samba](https://github.com/karakawa88/kacpp-samba)

