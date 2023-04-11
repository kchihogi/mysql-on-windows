# mysql-on-windows

WindowsベースOSイメージ上にMYSQLをインストール

[English README](../README.md)

## 概要

このDockerfileは、Chocolateyパッケージマネージャーを使用してMySQLをインストールするWindowsベースのイメージ用のものです。このイメージは、コンテナ化された環境でMySQLベースのアプリケーションを実行するためのベースイメージとして使用できます。

## 構築

このDockerイメージを使用するには、システムにDockerをインストールする必要があります。Dockerをインストールしたら、次のコマンドを使用してイメージをビルドできます。

```bash
docker build -t my-mysql-image .
```

これにより、名前が my-mysql-image のDockerイメージが作成されます。

次に、以下のコマンドを使用してコンテナを実行できます。

```bash
docker run --name my-mysql-container -e
```

MYSQL_ROOT_PASSWORD=my-secret-password -d my-mysql-image
これにより、名前が my-mysql-container のコンテナが作成され、ルートパスワードが my-secret-password に設定され、デタッチモードで実行されます。

## カスタマイズ

このDockerfileは、ビルドプロセス中にカスタマイズ可能な3つの引数、BASE_IMAGE と MYSQL_VERSION と MYSQL_ROOT_PASSWORD を使用しています。たとえば、次のコマンドを実行して、特定のMySQLのバージョンとルートパスワードを設定してイメージをビルドできます。

```bash
docker build --build-arg MYSQL_VERSION=8.0.27 --build-arg MYSQL_ROOT_PASSWORD=my-new-password -t my-mysql-image .
```

これにより、MySQLのバージョンを8.0.27に設定し、ルートパスワードを my-new-password に設定してイメージをビルドします。

## ライセンス
このDockerfileは、MITライセンスの下で提供されています。
