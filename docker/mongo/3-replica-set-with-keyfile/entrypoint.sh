#!/bin/bash

args=( "$@" )
actual_id=$UID

len=${#args[@]}
keyFile=""

for (( i=0; i<$len; i++)); do
  if [[ ${args[$i]} = "--keyFile" ]]; then
    i=$((i+1))
    keyFile=${args[$i]}
  fi
done

chown mongodb:mongodb $keyFile

docker-entrypoint.sh $@