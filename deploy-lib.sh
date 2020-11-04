#!/bin/sh
#############################################################
##export DEBUG='anythingyouwant'
##export TARGET_PORT='22'
#export TARGET_SSH='root@192.168.3.236'
#export TARGET_PATH='/home/sandboxs/sandbox_cinema/api'
#export DOCKER_NAME='cinema-api'
#############################################################
## JAR file path
JAR=$1
if [ ! $JAR ];then 
  JAR='.'  # means get local jar
fi

usage() {
    echo ''
    echo 'Edit the script file with exporting below environment variables.'
    echo  export TARGET_SSH='root@192.168.3.236'
    echo  export TARGET_PATH='/home/sandboxs/sandbox_cinema/api'
    echo  export DOCKER_NAME='cinema-api'
    echo ''
    echo 'Usage:'
    echo 'sh deploy-lib.sh <jar> <ssh> <remoteApiPath> <dockerName>'
    echo 'e.g. sh deploy-web.sh . root@192.168.3.123 /home/sandboxs/sandbox_cinema/api cinema-api'
    echo ''
    exit
}

execute() {
    jar=$1

    ## REMOTE SSH core command
    command="
    cd ${TARGET_PATH};
    sh docker-deploy-lib.sh"

    ## add option in TARGET_PORT
    if [ $TARGET_PORT ];then
       TARGET_PORT="-P $TARGET_PORT"
    fi
    ## transfer jar file
    echo "=>scp $jar $TARGET_SSH:$TARGET_PATH/lib"
    if [ ! ${DEBUG} ];then
       scp $TARGET_PORT $jar $TARGET_SSH:$TARGET_PATH/lib
    fi
    
    ## deploy-lib core
    echo =>ssh $TARGET_PORT $TARGET_SSH "$command"
    if [ ! ${DEBUG} ];then
       ssh $TARGET_PORT $TARGET_SSH "$command"
    fi
}

get_lib_in_local_dir() {
  dirs='.'
  if [ -d target ];then
     dirs=". target"
  fi

  libs=$(ls $dirs | grep -E "[^-standalone|^app].jar")
  i=0
  for lib in $libs;do
     JAR=$lib
     i=$(($i+1))
  done

  if [ ! -f $JAR ];then 
     JAR=target/$JAR
  fi

  ##
  if [ $i != 1 ]; then
     JAR=()
     #echo 'No or multiple jar files.' > /dev/stderr
     #exit
  fi

  echo $JAR
}

get_lib_in_local_standalone() {
    standalone=$1
    jarFile=$(jar tf $standalone | grep $JAR | head -1)
    if [ ! $jarFile ];then
        echo $standalone not exist target file: $JAR
        exit
    fi
    jar xf $standalone $jarFile
    JAR=${jarFile##*/}
}

get_lib_by_maven() {
    ## BOOT-INF directory
    BOOT_INF=BOOT-INF
    inf_dir=$BOOT_INF/lib

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


#  main
## confirm parameters
if [[ $# -ne 4 ]] && [[ ! $DOCKER_NAME || ! $TARGET_PATH || ! $TARGET_SSH ]];then
    usage
elif [[ $# -eq 4 ]]; then
    TARGET_SSH=$2
    TARGET_PATH=$3
    DOCKER_NAME=$4
fi

## get jar: if jar not found then get lib jar from maven storage
if [[ $JAR == '.' ]]; then
   get_lib_in_local_dir
elif [ ! -f $JAR ]; then
    dirs='.'
    if [ -d target ];then
      dirs=". target"
    fi

    standalone=$(ls $dirs | grep -E 'app|*-standalone'.jar | head -1)
    if [ -f $standalone ];then
      get_lib_in_local_standalone $standalone
    else
       get_lib_by_maven "$@"
    fi
fi

## execute
if [ ! $JAR ];then
   echo no deploy lib ! >/dev/stderr
   exit
fi
if [ ! -f $JAR ];then
   echo $JAR not exists ! >/dev/stderr
   exit
fi
execute $JAR
