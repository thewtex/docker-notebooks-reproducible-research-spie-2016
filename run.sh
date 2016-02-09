#!/bin/sh

daemon_container=docker-daemon
daemon_image="docker:1.9-dind"
notebook_container=docker-notebook
notebook_image="insighttoolkit/docker-notebooks-tutorial:2016-spie"
port=8888

which docker 2>&1 >/dev/null
if [ $? -ne 0 ]; then
	echo "Error: the 'docker' command was not found.  Please install docker."
	exit 1
fi

os=$(uname)
if [ "${os}" != "Linux" ]; then
	vm=$(docker-machine active 2> /dev/null || echo "default")
	if ! docker-machine inspect "${vm}" &> /dev/null; then
		if [ -z "$quiet" ]; then
			echo "Creating machine ${vm}..."
		fi
		docker-machine -D create -d virtualbox --virtualbox-memory 2048 ${vm}
	fi
	docker-machine start ${vm} > /dev/null
    eval $(docker-machine env $vm --shell=sh)
fi

running=$(docker ps -a -q --filter "name=${daemon_container}")
if [ -n "$running" ]; then
	if [ -z "$quiet" ]; then
		echo "Stopping and removing the previous daemon container"
		echo ""
	fi
	docker stop $daemon_container >/dev/null
	docker rm $daemon_container >/dev/null
fi
running=$(docker ps -a -q --filter "name=${notebook_container}")
if [ -n "$running" ]; then
	if [ -z "$quiet" ]; then
		echo "Stopping and removing the previous notebook container"
		echo ""
	fi
	docker stop $notebook_container >/dev/null
	docker rm $notebook_container >/dev/null
fi

docker run \
  --privileged \
  --name $daemon_container \
  -d \
  $daemon_image > /dev/null

ip=$(docker-machine ip ${vm} 2> /dev/null || echo "localhost")
url="http://${ip}:$port"

echo ""
echo "Setting up the notebook container..."
echo ""
echo "Point your web browser to ${url}"
echo ""
pwd_dir="$(pwd)"
mount_local=""
if [ "${os}" = "Linux" ] || [ "${os}" = "Darwin" ]; then
  mount_local=" -v ${pwd_dir}:/home/jovyan/notebooks "
fi
port_arg="-p $port:8888"

docker run \
  --link ${daemon_container}:docker \
  --name ${notebook_container} \
  -d \
  ${mount_local} \
  $port_arg \
  $notebook_image > /dev/null

trap "docker stop $notebook_container >/dev/null && docker stop $daemon_container >/dev/null" SIGINT SIGTERM

docker wait $notebook_container >/dev/null

# vim: noexpandtab shiftwidth=4 tabstop=4 softtabstop=0
