#!/bin/bash
# Usage:
#   ./init.sh volume_1 volume_2
#   ./init.sh # This will take all the volumes in the current machine

# You have to set the context to which the volumes are going
context="another"
volumes="$@"
if [[ $# -eq 0 ]]; then
  # If there are not volumes passed as parameters, we get all the local volumes
  volumes=$(docker volume ls --filter driver=local --format="{{.Name}}")
fi

volume_docker=""
for volume in ${volumes}; do volume_docker+="--volume=${volume}:/volumes/${volume} "; done

docker image build --tag migrate-volumes:latest --file ./Dockerfile.server --no-cache .

# Remove the container if it is working
if [[ $(docker container ls --all --quiet --filter name=^server$ --no-trunc) ]]; then docker container stop server; fi

docker container run --rm --name server --detach --publish 7899:80 ${volume_docker} migrate-volumes:latest

server_ip=""
if [[ -z $context ]]; then
  server_ip="$(docker container inspect server --format={{.NetworkSettings.IPAddress}}):80"
else
  server_ip=$(docker context inspect $actual_context --format={{.Endpoints.docker.Host}} | cut -d'/' -f3 | cut -d':' -f1)
fi

echo "server ip of the nginx container is: $server_ip"

docker context use $context

docker image build --tag migrate-volumes-client:latest --file ./Dockerfile.client --no-cache .

if [[ $(docker container ls --all --quiet --filter name=^client$ --no-trunc) ]]; then docker container rm -f client; fi

docker container run --name client -e TARGET_IP=":80" -e VOLUMES="$volumes" --detach ${volume_docker} migrate-volumes-client:latest
