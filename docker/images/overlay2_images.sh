#!/bin/bash

docker system info --format='{{.Driver}}'

### Simple test of overlay filesystem
# overlay
# |___ first
# |     |___ upperdir
# |     |___ workdir
# |
# |___ lowerdir
# |   |____ file1.txt
# |   |____ file2.txt
# |   |____ file3.txt
# |
# |___ merged
# |
# |___ second
#     |_____ upperdir
# 	  |_____ workdir
#
mkdir -p overlay/{first,second}/{upperdir,workdir}
mkdir -p overlay/{lowerdir,merged}
mkdir -p overlay/merged/{first,second}

touch overlay/lowerdir/file{1,2,3}.txt

folders=(first second)
for folder in ${folders[@]}; do
	mount -t overlay overlay \
		-o lowerdir=overlay/lowerdir \
		-o upperdir=overlay/${folder}/upperdir \
		-o workdir=overlay/${folder}/workdir \
		overlay/merged/${folder}
done

# We can visualize the overlay file systems mounted here
df -h | grep overlay

# If we remove the file1.txt from first folder
rm overlay/merged/first/file1.txt

file overlay/first/upperdir/file1.txt
ls -al overlay/first/upperdir/file1.txt

# Add some text to file2.txt from second folder
echo "Hello world!" >> overlay/merged/second/file2.txt

file overlay/second/upperdir/file2.txt
ls -al overlay/second/upperdir/file2.txt


### Some docker examples
docker image pull docker.io/library/alpine:3.16

graphDriverPath=$(docker image inspect \
	$(docker image ls --no-trunc --quiet --filter 'reference=alpine:3.16') \
	--format='{{.GraphDriver.Data.MergedDir}}')
graphDriverPath=${graphDriverPath%/merged}

ls -alL /var/lib/docker/overlay2/l/$(cat ${graphDriverPath}/link)

### alpine container
ID=$(docker container run -itd alpine:3.16 /bin/sh)

sleep 2
docker container exec -it ${ID} /bin/sh -c "echo hello world > new_file"

graphDriverPath=$(docker container inspect ${ID} --format='{{.GraphDriver.Data.MergeDir}}')
graphDriverPath=${graphDriverPath%/merged}

mount | grep $graphDriverPath

ls -al ${graphDriverPath} # diff link lower merged work
# It shows the upper layer
ls -alL /var/lib/docker/overlay2/l/$(cat ${graphDriverPath/link})
file ${graphDriverPath}/diff/new_file
# lower which shows links 
while read link; do
	echo /var/lib/docker/overlay2/l/${link};
	ls -alL /var/lib/docker/overlay2/l/${link};
done < <(cat /var/lib/docker/overlay2/${graphDriverPath}/lower | sed 's/\:/\n/g' | cut -d'/' -f2)
# Notice that in the lower file we have the link to the container layer and to the image layer (alpine one)

## Keep studying on https://docs.docker.com/storage/storagedriver/overlayfs-driver/
