ARG BASE_IMAGE=mcr.microsoft.com/dotnet/sdk:6.0-windowsservercore-ltsc2019
FROM ${BASE_IMAGE}

ENV chocolateyVersion=1.4.0

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG MYSQL_VERSION=8.0.27

# Install Chocolatey
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install MySQL
RUN choco install -y mysql --version $env:MYSQL_VERSION --params "/InstallLocation=C:\mysql /Password:"

# Add MySQL to the PATH
RUN setx /M PATH $('C:\mysql\bin;' + $env:PATH)

# Override docker-entrypoint.ps1 to run the password change script
COPY ./docker-entrypoint.ps1 C:/mysql/bin/docker-entrypoint.ps1

ENTRYPOINT ["powershell","C:/mysql/bin/docker-entrypoint.ps1"]
