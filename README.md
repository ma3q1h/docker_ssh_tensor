# Docker_ssh for tensorflow-gpu
`docker_ssh_sample3`をベースにtesnsorflow-gpuが動作するDockerfileにアレンジしました  
詳しい説明はdocker_ssh_sample3を参照してください  
なお、本環境ではjupyter notebookのポート解放などを省略しています  

## 直ぐに環境を使う為の手順
## 1. 想定  
クライアント：各自のノートPCなど  
ホスト/dockerサーバ：共有サーバなど  
ホストはdocker, compose, nvidiaコンテナの整備が済んでいるとします  
クライアントとホストはssh接続が済んでいるとします  
ssh接続チートシート(windows) 
```sh
# 公開鍵生成
https://qiita.com/overflowfl/items/14a2486df85fd7efac85 を参照
# ホスト側の公開鍵保存先 .sshディレクトリの存在を忘れずに
$ mkdir ~/.ssh
# 公開鍵配布(win to linux)
scp -P 22 C:/Users/${client_USER}/.ssh/id_rsa.pub ${host_USER}@{host_ip}:~/.ssh/authorized_keys
``` 
このリポジトリをユーザーのホームディレクトリに置くこととします  
また、/${USER_HOME}/.ssh にクライアントの公開鍵があることを確認してください

## 2. make_env編集  
.envを生成する実行ファイルです. `make_env.sh`の`cat`部分を編集・追記してください
```sh
BASE_IMAGE="tensorflow/tensorflow:2.6.0-gpu"  # ベースとなるdocker-imageリポジトリ (tensorflow-gpuイメージ)
COMPOSE_PROJECT_NAME="projectname-`whoami`"    # 'projectname'部分のみを編集してください(見た目上"-"は残すのがオススメ)
USER=`whoami`                                  # ホストPCのユーザー名が展開されます
UID=`id -u`                                    # ホストPCのUIDが展開されます
GID=`id -g`                                    # ホストPCのGIDが展開されます
USER_PASSWD="user"                             # コンテナ内ユーザーのパスワードの指定
ROOT_PASSWD="root"                             # コンテナ内rootのパスワード指定
PYTHON_VERSION="3.9.17"                        # pythonのバージョンの指定
MEM="4g"                                       # コンテナとホストPCとの共有メモリ容量
SSH_PORT="22"                                  # 以下各ポート設定
HOST_PORT="23"
CONTAINER_PORT="22"
```
サーバを複数人で共有すると仮定すると, ここのprojectnameでは被らない名前を付けることが重要です (whoamiの参照でデフォルトでも被らないようになっています)  
#出来上がるdocker コンテナとイメージの名前: \${projectname}-\${USERNAME}-\${SERVICENAME}-\${1, 2, ...}

## 3. ディレクトリ関係  
1. src  
このディレクトリは仮想環境内にコピーされます  
環境構築時などに使うソースコードを保存するディレクトリとしています。デフォルトではrequirement.txtを配置しています  
2. work  
このディレクトリは仮想環境とマウントされます。つまり、ローカルと仮想環境で同期されるディレクトリです  
仮想環境を閉じたり、破壊してもこのディレクトリは消えません  
実験プログラムや生成データなどを保存すると良いでしょう。
デフォルトではtest.ipynbが置いてあります  
3. データディレクトリ  
適宜必要なデータディレクトリをマウントしてください

## 4. 仮想環境のビルドとdocker運用
チートシートです  
```sh
# 仮想環境イメージとコンテナのビルドと起動
$ ./compose_up.sh
# イメージの確認
$ docker images
# イメージの削除
$ docker rmi {Image_ID}
# コンテナの確認(オプション -a で停止中も表示)
$ docker ps
# コンテナの削除
$ docker rm {Container_ID}
# コンテナの開始/再起動/停止
$ docker start/restart/stop {Container_ID} 
# 起動中のコンテナに入る
docker exec -it {Container_ID} /bin/bash
```
実験環境が整ったらコンテナに直接SSHでアクセスするのが便利で楽です クライアントのローカルvscodeからワンクリックで飛べます！  

デフォルトではホストの23に接続するようにしています  
クライアントPC側SSH_config例（windows）  
```
Host {ホストSSH名}
	HostName {ホストIPアドレス}
	User {ホストPCユーザー名}
	IdentityFile C:\Users\{USER}\.ssh\id_rsa    # クライアントPCの公開鍵の場所
	LocalForward 8888 localhost:8888            #ポートフォワーディング（やるなら）
	Port 22
	Port 23

Host {コンテナSSH名}
	HostName localhost
	Port 23
	User {コンテナユーザー名}
	IdentityFile ~/.ssh/id_rsa
	ProxyCommand ssh -W %h:%p {ホストSSH名}
```
接続できないときは known_hostsなどを初期化