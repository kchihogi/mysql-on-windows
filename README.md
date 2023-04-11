# mysql-on-windows

MySQL installed on Windows base OS images.

[Japanese(日本語) README](docs/README.jp.md)

## Overview

This is a Dockerfile for a Windows-based image that installs MySQL using Chocolatey package manager. The resulting image can be used as a base for running MySQL-based applications in a containerized environment.

## Getting Started

To use this Docker image, you will need to have Docker installed on your system. Once you have Docker installed, you can build the image using the following command:

```bash
docker build -t my-mysql-image .
```

This will create a Docker image with the name my-mysql-image.

You can then run a container using the following command:

```bash
docker run --name my-mysql-container -e MYSQL_ROOT_PASSWORD=my-secret-password -d my-mysql-image
```

This will create a container with the name my-mysql-container, set the root password to my-secret-password, and run it in detached mode.

## Customization

This Dockerfile uses three arguments, BASE_IMAGE, MYSQL_VERSION, and MYSQL_ROOT_PASSWORD, which can be customized during the build process. For example, you can build the image with a specific version of MySQL and root password by running the following command:

```bash
docker build --build-arg MYSQL_VERSION=8.0.27 --build-arg MYSQL_ROOT_PASSWORD=my-new-password -t my-mysql-image .
```

This will build the image with MySQL version 8.0.27 and set the root password to my-new-password.

## License

This Dockerfile is licensed under the MIT License.
