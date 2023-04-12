# mysql-on-windows

WindowsベースOSイメージ上にMYSQLをインストール

[English README](../README.md)

## 概要

このDockerfileは、Chocolateyパッケージマネージャーを使用してMySQLをインストールするWindowsベースのイメージ用のものです。このイメージは、コンテナ化された環境でMySQLベースのアプリケーションを実行するためのベースイメージとして使用できます。

## 構築

このDockerイメージを使用するには、システムにDockerをインストールする必要があります。Dockerをインストールしたら、次のコマンドを使用してイメージをビルドできます。

```powershell
docker build -t my-mysql-image .
```

これにより、名前が my-mysql-image のDockerイメージが作成されます。

次に、以下のコマンドを使用してコンテナを実行できます。

```powershell
docker run --name my-mysql-container -e MYSQL_ROOT_PASSWORD=my-secret-password -d my-mysql-image
```

MYSQL_ROOT_PASSWORD=my-secret-password -d my-mysql-image
これにより、名前が my-mysql-container のコンテナが作成され、ルートパスワードが my-secret-password に設定され、デタッチモードで実行されます。

次のコマンドを使用してコンテナを実行することもできます。

```powershell
docker run -p 3306:3306 -v ${pwd}\data:C:\ProgramData\MySQL\data:RW --name my-mysql-container -e MYSQL_ROOT_PASSWORD=my-secret-password -d my-mysql-image
```

このコマンドでは、ホストのカレントディレクトリをコンテナのMySQLデータディレクトリにマップすることで、データをコンテナの外側に保存することができます。また、ポート3306を公開することでMySQLサーバーへの外部接続を許可します。

## カスタマイズ

このDockerfileは、ビルドプロセス中にカスタマイズ可能な2つの引数、BASE_IMAGE と MYSQL_VERSION を使用しています。たとえば、次のコマンドを実行して、特定のMySQLのバージョンとルートパスワードを設定してイメージをビルドできます。

```powershell
docker build --build-arg MYSQL_VERSION=8.0.27 -t my-mysql-image .
```

これにより、MySQLのバージョンを8.0.27に設定します。

## ライセンス

このDockerfileは、MITライセンスの下で提供されています。
