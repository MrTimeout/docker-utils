FROM ubuntu:22.04

RUN apt-get update --yes && apt-get install --yes wget libc6-dev gcc make && \
  wget https://github.com/neurobin/shc/archive/release.tar.gz -O /tmp/release.tar.gz && \
  tar -xzf /tmp/release.tar.gz -C /tmp && \
  cd /tmp/shc-release && ./configure && make && make install

ENTRYPOINT ["/bin/bash", "-c"]

