#!/bin/bash

# Removing all the images that are not being used by another container
while read image; do
  name=${image% *}
  id=${image#* }
  echo "Removing image with name ${name} and ID ${id}"
  docker image rm ${id}; 
done < <(docker image ls --no-trunc --format='{{.Repository}}:{{.Tag}} {{.ID}}')
