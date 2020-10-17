#!/bin/sh
#############################################################
export TARGET_PORT='6000'
export TARGET_SSH='root@115.231.158.31'
export REMOTE_API_PATH='/home/sandboxs/sandbox_cinema/api'
export DOCKER_NAME='cinema-api'
export JAR_STANDALONE='app.jar'
#############################################################
## JAR file path
JAR=$1
## rollback rename format
rollback=app.rollback_$(date "+%m-%d")
## BOOT-INF directory
BOOT_INF=BOOT-INF
inf_dir=$BOOT_INF/lib
## REMOTE SSH core command
command='
cd $REMOTE_API_PATH;
if [ -d $JAR_STANDALONE ];then
	cp $JAR_STANDALONE $rollback;
else
	echo $JAR_STANDALONE NOT found
	rm -rf $inf_dir;
	exit
fi
if [ -f predeploy.sh ];then
	sh ./predeploy.sh rollback keep dist.rollback_ 6;
fi
docker exec $DOCKER_NAME jar 0uf $JAR_STANDALONE $inf_dir/$JAR;
rm -rf $inf_dir;
docker restart $DOCKER_NAME;'

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
if [[ $JAR != '.' ]] && [[ ! -f $JAR ]]; then
    get_lib_by_maven "$@"
elif [[ $JAR == '.' ]]; then
    num=$(ls -l | grep "[^-standalone].jar" | wc -l)
    if [ $num -ne 1 ]; then
        JAR=$(ls . | grep "[^-standalone].jar" | head -n 1)
    else   
        echo 'No or multiple jar files.'
        exit
    fi
fi
if [ -d $inf_dir ]; then
    rm -rf $inf_dir
fi
mkdir -p $inf_dir
cp $JAR $inf_dir
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
ssh $TARGET_PORT $TARGET_SSH "$command"
exit