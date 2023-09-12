#!/bin/bash

#mount working dir
if [ ! -d ./work ]; then
	mkdir work
fi

#pub key
if [ ! -e ~/.ssh/authorized_keys ]; then
	echo 'authorized_keys does not exist'
	exit 0
fi
cp ~/.ssh/authorized_keys id_rsa.pub

#make .env
./make_env.sh

#compose up
docker compose up -d