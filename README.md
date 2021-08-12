# kacpp-samba Sambaサーバーイメージ

## 概要
SambaサーバーをソースからインストールしてSambaを起動実行するイメージ。

## バージョン
Sambaのバージョンは4.14.6です。

## 使い方
```shell
# Dockerでの使い方
docker image pull kagalpandh/kacpp-samba
docker run -dit --name kacpp-samba kagalpandh/kacpp-samba
# Sambaサーバーの初期化スクリプト実行
docker exec -it kacpp-samba "/usr/local/sh/system/samba-init.sh"
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
### Sambaユーザーが自動で作成されない理由
pdbeditでパスワードを入力する必要がありしかも標準入力でパスワードを渡せないため。
後日修正される可能性あり。

## その他
ログは/var/log/samba/samba.logにあるものとしてある。
そしてそのログにはlogrotateの設定がされてありcronに登録されてある。


##構成
Sambaホーム         /usr/local/samba
設定ディレクトリ    /usr/local/etc/samba
設定ファイル        smb.conf
ログ                /var/log/samba.log

##ベースイメージ
kagalpandh/kacpp-pydev

# その他
DockerHub: [kagalpandh/kacpp-samba](https://hub.docker.com/repository/docker/kagalpandh/kacpp-samba)<br />
GitHub: [karakawa88/kacpp-samba](https://github.com/karakawa88/kacpp-samba)

