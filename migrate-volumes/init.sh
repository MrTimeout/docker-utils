#!/bin/bash
# Usage:
#   ./init.sh volume_1 volume_2
#   ./init.sh # This will take all the volumes in the current machine

# You have to set the context to which the volumes are going
server_ip=""
server_port=7899
actual_context=$(docker context ls | grep \* | awk '{print $1}')
target_context=""
volumes="$@"

if [[ $# -eq 0 ]]; then
  # If there are not volumes passed as parameters, we get all the local volumes
  volumes=$(docker volume ls --filter driver=local --format="{{.Name}}")
fi

# build_volumes is used to create the string parameters containing all the volumes needed.
#   ...volumes: string of volumes to parse. If no one is passed it is assumed that we have to use all the local docker volumes.
#   return: the string containing all the volumes as docker parameters
build_volumes() {
  volumes=$@

  volume_docker=""
  for volume in ${volumes}; do volume_docker+="--volume=${volume}:/volumes/${volume} "; done

  echo $volume_docker
}

# build_server is used to build the server docker image and run it.
#   server_port: to publish the server.
#   volume_docker: string containing all the docker parameters to create the volumes.
build_server() {
  if [[ $# -ne 2 ]]; then echo "build_server error because parameters are incorrect"; exit 2; fi

  server_port=$1
  volume_docker=$2

  docker image build --tag migrate-volumes:latest --file ./Dockerfile.server --no-cache .

  if [[ $(docker container ls --all --quiet --filter name=^server$ --no-trunc) ]]; then docker container stop server; fi

  docker container run --rm --name server --detach --publish ${server_port}:80 ${volume_docker} migrate-volumes:latest
}

# build_client is used to build the client docker image and run it.
#   server_ip: where the server is. It corresponds to the before calculated context ip.
#   volumes: string containing all the volumes needed to parse.
#   volume_docker: string containing all the docker parameters to create the volumes.
build_client() {
  if [[ $# -ne 3 ]]; then echo "build_client error because parameters are incorrect"; exit 3; fi

  server_ip=$1
  volumes=$2
  volume_docker=$3

  docker image build --tag migrate-volumes-client:latest --file ./Dockerfile.client --no-cache .

  if [[ $(docker container ls --all --quiet --filter name=^client$ --no-trunc) ]]; then docker container rm -f client; fi

  docker container run --name client -e TARGET_IP="${server_ip}" -e VOLUMES="$volumes" --detach ${volume_docker} migrate-volumes-client:latest
}

volume_docker=$(build_volumes $volumes)
echo $volume_docker

build_server $server_port "$volume_docker"

# Set IP address of the first docker host
if [[ -z $target_context ]]; then
  server_ip="$(docker container inspect server --format={{.NetworkSettings.IPAddress}}):80"
else
  server_ip="$(docker context inspect $actual_context --format={{.Endpoints.docker.Host}} | cut -d'/' -f3 | cut -d':' -f1):$server_port"
  docker context use $target_context
fi

echo "server ip of the nginx container is: $server_ip"

build_client $server_ip "$volumes" "$volume_docker"

counter=1
backoff=5s
while [[ $(docker container ls --filter name=^client$ | grep -E client) ]]; do
  echo "Checking if docker container has finished its process or not in $counter attempt"
  sleep $backoff
  counter=$((counter + 1))
done

if [[ -n $target_context ]]; then
  docker context use $actual_context
fi

docker container stop server

if [[ -n $target_context ]]; then
  docker context use $target_context
fi

echo "Check your volumes using $(docker context ls | grep \* | awk '{print $1}')"