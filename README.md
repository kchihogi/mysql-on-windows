# mysql-on-windows

MySQL installed on Windows base OS images.

[Japanese(日本語) README](docs/README.jp.md)

## Overview

This is a Dockerfile for a Windows-based image that installs MySQL using Chocolatey package manager. The resulting image can be used as a base for running MySQL-based applications in a containerized environment.

## Getting Started

To use this Docker image, you will need to have Docker installed on your system. Once you have Docker installed, you can build the image using the following command:

```powershell
docker build -t my-mysql-image .
```

This will create a Docker image with the name my-mysql-image.

You can then run a container using the following command:

```powershell
docker run --name my-mysql-container -e MYSQL_ROOT_PASSWORD=my-secret-password -d my-mysql-image
```

This will create a container with the name my-mysql-container, set the root password to my-secret-password, and run it in detached mode.

Or you can run a container using the following command:

```powershell
docker run -p 3306:3306 -v ${pwd}\data:C:\ProgramData\MySQL\data:RW --name my-mysql-container -e MYSQL_ROOT_PASSWORD=my-secret-password -d my-mysql-image
```

This will map the host's current working directory to the container's MySQL data directory, allowing data to persist outside of the container. It also exposes port 3306 to allow external connections to the MySQL server.

## Customization

This Dockerfile uses two arguments, BASE_IMAGE and MYSQL_VERSION, which can be customized during the build process. For example, you can build the image with a specific version of MySQL by running the following command:

```powershell
docker build --build-arg MYSQL_VERSION=8.0.27 -t my-mysql-image .
```

This will build the image with MySQL version 8.0.27.

## License

This Dockerfile is licensed under the MIT License.
