#!/bin/sh
#############################################################
##export DEBUG='anythingyouwant'
##export TARGET_PORT='22'
#export TARGET_SSH='root@192.168.3.236'
#export TARGET_PATH='/home/sandboxs/sandbox_cinema/dist'
#export DOCKER_NAME='cinema-dist'
#############################################################
uasge() {
  echo ''
  echo 'Edit the script file with exporting below environment variables.'
  echo  export TARGET_SSH='root@192.168.3.100'
  echo  export TARGET_PATH='/home/sandboxs/sandbox_cinema/web'
  echo  export DOCKER_NAME='cinema-web'
  echo ''
  echo 'Usage:'
  echo '  sh deploy-web.sh'
  echo '  sh deploy-web.sh <dist> <ssh> <remoteDistPath> <dockerName>'
  echo '  <e.g. sh deploy-web.sh . root@192.168.3.123 /home/sandboxs/sandbox_cinema/dist cinema-dist>'
  echo ''
  exit
}

## current work directory
#workdir=$(cd $(dirname $0); pwd)

check() {
  ## confirm arameters
  if [[ $# -ne 3 ]] && [[ ! $DOCKER_NAME || ! $TARGET_PATH || ! $TARGET_SSH ]];then
    uasge
  fi

  if [ ! -d dist ];then
    echo dist dir not found in $(pwd).
    exit
  elif [[ $# -eq 3 ]];then
    TARGET_SSH=$1
    TARGET_PATH=$2
    DOCKER_NAME=$3
  fi
}

execute() {
  ## rollback rename format
  rollback=dist.rollback_$(date "+%m-%d")

  ## REMOTE SSH core command
  command="
  cd ${TARGET_PATH};
  if [ -d dist ];then
    tar zcf ${rollback} dist;
    rm -rf dist;
  fi
  if [ -f predeploy.sh ];then
    sh ./predeploy.sh rollback keep dist.rollback_ 6;
  fi
  tar zxf dist.tar.gz;
  rm dist.tar.gz;
  docker restart ${DOCKER_NAME};"
  ## package dist directory
  echo "=>tar zcvf dist.tar.gz dist"
  tar -zcvf dist.tar.gz dist
  ## transfer archive file
  echo "=>scp dist.tar.gz $TARGET_SSH:$TARGET_PATH"
  if [ $TARGET_PORT ];then
    TARGET_PORT="-P $TARGET_PORT"
  fi
  scp $TARGET_PORT dist.tar.gz $TARGET_SSH:$TARGET_PATH
  ## clean local storage
  rm dist.tar.gz
  if [[ $TARGET_PORT ]];then
    TARGET_PORT=${TARGET_PORT/-P/-p}
  fi
  ## clean remote storage and upzip archive 
  ## avoid multiple authentication ##
  ssh $TARGET_PORT $TARGET_SSH "$command"
  exit
}

check
execute