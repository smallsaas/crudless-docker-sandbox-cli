# crudless-docker-sandbox-cli

> Scripts used to deploy lib or dist at local side

## install

```shell
$ npm i -g 
```

### deploy-web
> Used to deploy local dist to remote server

##### prepare the script for your simple use
```shell
$ cat deploy-web-sandbox.sh
#!/bin/sh
#############################################################
#export TARGET_PORT='22'  #default to 22
export TARGET_SSH='root@192.168.3.100'
export TARGET_PATH='/home/sandboxs/sandbox_cinema/web'
export DOCKER_NAME='cinema-web'
#############################################################
deploy-web
```

### deploy-lib
> Used to deploy local lib jar to remote server

##### prepare the script for your simple use

```shell
$ cat deploy-lib-sandbox.sh
#!/bin/sh
#############################################################
#export TARGET_PORT='22'  #default to 22
export TARGET_SSH='root@192.168.3.100'
export TARGET_PATH='/home/sandboxs/sandbox_cinema/api'
export DOCKER_NAME='cinema-api'
#############################################################
deploy-lib
```

