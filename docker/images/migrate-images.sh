#!/bin/bash
#
# ./migrate-images ${CONTEXT_FROM} ${CONTEXT_TO} [--import]
#
# Example
#   docker image ls --filter=dangling=false --format='{{.Repository}}:{{.Tag}}' | grep -e 'repo/' -e 'repo/more' | ./migrate-images.sh ${CONTEXT_FROM} ${CONTEXT_TO}
#   cat docker-compose.yaml | yq '.services[].image' | ./migrate-images.sh ${CONTEXT_FROM} ${CONTEXT_TO}
#   docker image ls --all --filter=dangling=false --format='{{.Repository}}:{{.Tag}}' | grep -v '<none>' | ./migrate-images.sh ${CONTEXT_FROM} ${CONTEXT_TO}
#
# We can just import a bunch of images from a folder using the --import option

CONTEXT=$(docker context ls | grep '\*' | cut -d' ' -f1)
CONTEXT_FROM=$1
CONTEXT_TO=$2
JUST_IMPORT=$3

if ! [[ -p '/dev/stdin' ]]; then
  echo "There is not input image names"
  exit 1
fi

if [[ -z $JUST_IMPORT ]]; then
  test -d images && rm -rf images
  mkdir images

  docker context use ${CONTEXT_FROM}
  # / = _
  # : = __
  while IFS= read image_name; do
    output=$(echo ${image_name} | sed 's/\//_/g;s/:/__/g;').tar
    echo "Exporting ${image_name} to the file images/${output}"
    docker image save --output images/${output} ${image_name}
  done
fi

docker context use ${CONTEXT_TO}

while read image_tar; do
  image_name=$(echo ${image_tar%.*} | sed 's/__/:/g;s/_/\//g;')
  echo "Importing ${image_name} from ${image_tar}"
  docker image import ./images/${image_tar} ${image_name}
done< <(ls images)

docker context use ${CONTEXT}
