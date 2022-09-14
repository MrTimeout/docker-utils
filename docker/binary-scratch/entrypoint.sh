#!/bin/bash

docker image build --file ./Dockerfile --tag estenoesmiputonombre/shc:0.0.1 --no-cache .

docker container run --name testing-shc -d --volume ${PWD}/test:/test estenoesmiputonombre/shc:0.0.1 "/usr/local/bin/shc -f /test/my.sh -o /test/my.o && /test/my.o"

# docker container run --name testing-shc -it --rm --volume ${PWD}/test:/test --entrypoint /bin/bash estenoesmiputonombre/shc:0.0.1

# file ./test/my.o

