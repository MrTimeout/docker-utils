#!/bin/sh

ip=${TARGET_IP}
if [[ -z "$TARGET_IP" ]]; then
  ip=localhost:80
fi

mkdir --parent /volumes/tars

# Starting backoff stuff
counter=10
server_up=0
backoff=5s
echo "" > ./result.txt
while [[ $server_up -eq 0 ]] && [[ $counter -gt 0 ]]; do
  curl -X GET http://$ip/ping -o ./result.txt
  server_up="$(grep -c OK ./result.txt)"
  echo "waiting $backoff for the server"
  sleep $backoff
  counter=$((counter - 1))
done

if [[ $counter -eq 0 ]] && [[ $server_up -eq 0 ]]; then
  echo "server is not up and running"
  exit 1
fi
# Ending backoff stuff

for volume in ${VOLUMES}; do 
  url=http://$ip/${volume}.tar.gz
  echo "Fetching $url";
  curl -X GET $url -o /volumes/tars/${volume}.tar.gz
  tar -xvzf /volumes/tars/$volume.tar.gz -C /volumes
done
