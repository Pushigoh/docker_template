#!/bin/bash
###Creates directory with Docker build/run scripts for new container
user=$(whoami)

#Check if $1 argument was passed in
if [ -z "$1" ]
then
    echo 'Usage: buildContainerShell $containerName [$baseImage]'
    exit
fi
#Abathur Integration
#! If .abathur is found, script will only use Abathur variablies.
imagedir="$(pwd)/${1}"
if [ -f "/home/$user/.abathur" ]; then
    source /home/$user/.abathur
    imagedir=$workDIR/${1}
fi
#Create base files
mkdir $imagedir
touch $imagedir/Dockerfile
touch $imagedir/build.sh
touch $imagedir/run.sh
mkdir $imagedir/storage
redisContainer="--link redisserver:redis"

#create Dockerfile
##If $2 is null, default to ubuntu:latest
if [ -z "$2" ]
then
    echo "FROM ubuntu:latest" >> "$imagedir/Dockerfile"
else
    echo "FROM $2" >> "$imagedir/Dockerfile"
fi
##Update package manager, install basic utilities, create storage volume
function fillutils {
	utilities=(
	redis-tools
	vim
	git
	wget
	)
	echo "RUN apt-get update && apt-get upgrade -y" >> $imagedir/Dockerfile
	for i in ${utilities[@]}
	do
		echo "RUN apt-get install $i -y" >> $imagedir/Dockerfile
		echo "RUN apt-get install $i -y"
	done
	echo "RUN wget https://raw.githubusercontent.com/Pushigoh/vimrc/master/.vimrc" >> $imagedir/Dockerfile
}
fillutils
echo "RUN apt-get update && apt-get upgrade -y" >> $imagedir/Dockerfile
echo "RUN apt-get install man -y" >> $imagedir/Dockerfile
echo "RUN apt-get install redis-tools -y" >> $imagedir/Dockerfile
echo "RUN apt-get install vim -y" >> $imagedir/Dockerfile
echo "RUN apt-get install git -y" >> $imagedir/Dockerfile
echo "RUN apt-get install wget -y" >> $imagedir/Dockerfile
echo "RUN echo \"PS1='root@${1}: '\" >> ~/.bashrc" >> $imagedir/Dockerfile
echo "RUN mkdir /storage" >> $imagedir/Dockerfile

#Create build.sh
echo "docker build -t $1 $imagedir" >> $imagedir/build.sh

#Create run.sh
##Runs with interactive shell, removes container on exit
###Runs detached if passed -d
cat >$imagedir/run.sh << EOL
re='^[0-9]+$'
if [ "\$1" = '-d' ]
then
  docker run --name $1 -v $imagedir/storage:/storage $redisContainer -it -d $1
elif [[ "\$1" =~ \$re ]]
then
  for i in {1..\$1}
    do
      docker run -d $1
    done
else
  docker run --name $1 -v $imagedir/storage:/storage $redisContainer -it --rm $1
fi
EOL

#Grant permissions to execute run.sh && build.sh
chmod +x $imagedir/run.sh && chmod +x $imagedir/build.sh

