#!/bin/sh
#############################################################
#export TARGET_PORT='6000'
#export TARGET_SSH='root@115.231.158.31'
#export REMOTE_WEB_PATH='/home/sandboxs/sandbox_cinema/dist'
#export DOCKER_NAME='dist'
#############################################################
rollback=dist.rollback_$(date "+%m-%d")
workdir=$(cd $(dirname $0); pwd)

## confirm arameters
if [[ $# -ne 3 ]] && [[ ! $DOCKER_NAME || ! $REMOTE_WEB_PATH || ! $TARGET_SSH ]];then
  echo ''
  echo 'Get the environment variables in the script file by default.'
  echo ''
  echo 'Usage:'
  echo 'sh deploy-web.sh <ssh> <remoteDistPath> <dockerName>'
  echo 'e.g. sh deploy-web.sh root@192.168.3.123 /home/sandboxs/sandbox_cinema/dist cinema-dist'
  echo ''
  exit
fi

if [ ! -d dist ];then
  echo Dist not found in $(pwd).
  exit
elif [[ $# -eq 3 ]];then
  TARGET_SSH=$1
  REMOTE_WEB_PATH=$2
  DOCKER_NAME=$3
fi
## package dist directory
echo "=>tar zcvf dist.tar.gz dist"
tar -zcvf dist.tar.gz dist
## transfer archive file
echo "=>scp dist.tar.gz $TARGET_SSH:$REMOTE_WEB_PATH"
if [ $TARGET_PORT ];then
  TARGET_PORT="-P $TARGET_PORT"
fi
scp $TARGET_PORT dist.tar.gz $TARGET_SSH:$REMOTE_WEB_PATH
## clean local storage
rm dist.tar.gz
if [[ $TARGET_PORT ]];then
  TARGET_PORT=${TARGET_PORT/-P/-p}
fi
## clean remote storage and upzip archive 
## avoid multiple authentication ##
ssh $TARGET_PORT $TARGET_SSH "cd $REMOTE_WEB_PATH && tar zcf $rollback dist && sh ./predeploy.sh rollback keep dist.rollback_ 6 && tar zxf dist.tar.gz && rm dist.tar.gz && docker restart $DOCKER_NAME"
exit