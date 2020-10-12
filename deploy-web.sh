package=$1
ssh=$2
name=$3
rollback=dist.rollback_$(date "+%m-%d")

## confirm the number of parameters
if [[ $# -ne 3 ]];then
  echo ''
  echo 'e.g. sh deploy-web.sh dist root@192.168.3.123 cinema'
  echo ''
  exit
fi

## ready for the path
echo "=>ssh $ssh \"mkdir -p ~/$name/web\""
ssh $ssh "if [ ! -d ~/$name/web ];then mkdir -p  ~/$name/web; elif [ -d ~/$name/web/dist ];then rm -rf ~/$name/web/dist; fi"

## cp dist to ssh
if [[ $package == dist ]];then
  ## package dist directory
  echo "=>tar zcvf dist.tar.gz dist"
  tar zcvf dist.tar.gz dist
  ## transfer archive file
  echo "=>scp dist.tar.gz $ssh:~/$name/web"
  scp dist.tar.gz $ssh:~/$name/web
  ## clean local storage
  rm dist.tar.gz
  ## clean remote storage and upzip archive 
  ## avoid multiple authentication ##
  echo "=>ssh $ssh \"cd ~/$name/web && cp -r dist $rollback && bash ./predeploy.sh rollback keep dist.rollback_ 6  && tar zxvf dist.tar.gz && rm dist.tar.gz\""
  ssh $ssh "cd ~/$name/web 
  && cp -r dist $rollback 
  && bash ./predeploy.sh rollback keep dist.rollback_ 6 
  && tar zxvf dist.tar.gz
  && rm dist.tar.gz
  && docker-compose restart $name-web"
else
  ## package name illegal
  echo $package directory illegal
fi

exit