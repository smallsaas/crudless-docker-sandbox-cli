## crudless-docker-sandbox-cli

>Some tiny script tools in cli maner

### install

```shell
$ npm i -g 

## or below two lines after clone

$ npm install
$ npm link
```

### deploy-web

> Used to deploy local dist to remote server

```shell
$ bash deploy-web.sh

Get the environment variables in the script file by default.

Usage:
sh deploy-web.sh <ssh> <remoteDistPath> <dockerName>
e.g. sh deploy-web.sh root@192.168.3.123 cinema
```