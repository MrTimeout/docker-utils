#!/bin/bash

mkdir --parent /volumes/tars
for volume in $(ls /volumes); do tar -czvf /volumes/tars/$volume.tar.gz /volumes/$volume; done

cat <<EOF > /etc/nginx/conf.d/default.conf
server {
  listen  80;
  server_name localhost;

  root /volumes/tars;

  location / {

  }

  # This is used just to test if the server is up and running
  location /ping {
    return 200 'OK';
  }
}
EOF

echo "Done"