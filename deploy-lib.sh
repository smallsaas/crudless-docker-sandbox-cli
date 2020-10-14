#!/bin/sh
#############################################################
export TARGET_PORT='6000'
export TARGET_SSH='root@115.231.158.31'
export REMOTE_API_PATH='/home/sandboxs/sandbox_cinema/api'
export DOCKER_NAME='cinema-api'
#############################################################
JAR=$1
rollback=app.rollback_$(date "+%m-%d")
BOOT_INF=BOOT-INF
inf_dir=$BOOT-INF/lib

usage() {
    echo ''
    echo 'Get the environment variables in the script file by default.'
    echo ''
    echo 'Usage:'
    echo 'sh deploy-lib.sh <jar> <ssh> <remoteApiPath> <dockerName>'
    echo 'e.g. sh deploy-web.sh crud-plus root@192.168.3.123 /home/sandboxs/sandbox_cinema/api cinema-api'
    echo ''
    exit
}

get_lib_by_maven() {
    num=$(echo $JAR | awk -F":" '{print NF-1}')
    if [ $JAR ]; then
        if [ $num -eq 0 ]; then
            JAR="com.jfeat:${JAR}:1.0.0"
        elif [ $num -eq 1 ]; then
            JAR="com.jfeat:${JAR}"
        fi
    else
        usage
    fi
    if [ -d $inf_dir ]; then
        rm -rf $inf_dir
    fi
    mkdir -p $inf_dir
    mvn dependency:get -Dartifact=$JAR -Ddest=./$inf_dir
    JAR=$(ls $inf_dir | head -n 1)
}

## confirm arameters
if [[ $# -ne 4 ]] && [[ ! $DOCKER_NAME || ! $REMOTE_API_PATH || ! $TARGET_SSH ]]; then
    usage
elif [[ $# -eq 4 ]]; then
    TARGET_SSH=$2
    REMOTE_API_PATH=$3
    DOCKER_NAME=$4
fi

## if jar not found then get lib jar from maven storage
if [[ ! -f $JAR ]]; then
    get_lib_by_maven "$@"
else
    if [ -d $inf_dir ]; then
        rm -rf $inf_dir
    fi
    mkdir -p $inf_dir
    cp $JAR $inf_dir
fi
## add option in TARGET_PORT
if [ $TARGET_PORT ];then
  TARGET_PORT="-P $TARGET_PORT"
fi
## transfer jar file
echo "=>scp $inf_dir $TARGET_SSH:$REMOTE_API_PATH"
scp $TARGET_PORT -r $BOOT_INF $TARGET_SSH:$REMOTE_API_PATH
## clean local storage
rm -rf $BOOT_INF
if [[ $TARGET_PORT ]];then
  TARGET_PORT=${TARGET_PORT/-P/-p}
fi
## deploy-lib core
ssh $TARGET_PORT $TARGET_SSH "cd $REMOTE_API_PATH && cp app.jar $rollback && sh ./predeploy.sh rollback keep app.rollback_ 6 && docker exec $DOCKER_NAME jar 0uf app.jar $inf_dir/$JAR && rm -rf $inf_dir && docker restart $DOCKER_NAME"
exit