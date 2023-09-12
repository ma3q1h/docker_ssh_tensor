#!/bin/bash
set -eu
cat <<EOT > .env
BASE_IMAGE="tensorflow/tensorflow:2.6.0-gpu"
COMPOSE_PROJECT_NAME="projectname-`whoami`"
USER=`whoami`
UID=`id -u`
GID=`id -g`
USER_PASSWD="user"
ROOT_PASSWD="root"
PYTHON_VERSION="3.9.17"
MEM="8g"
SSH_PORT="22"
HOST_PORT="23"
CONTAINER_PORT="22"
EOT

# do "docker compose config" and check