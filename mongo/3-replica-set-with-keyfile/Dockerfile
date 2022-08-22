## debian:11.4-slim
ARG TAG=@sha256:a811e62769a642241b168ac34f615fb02da863307a14c4432cea8e5a0f9782b8
ARG VERSION="1.5.4"
FROM debian${TAG}
ARG VERSION

RUN apt-get update && apt-get install --yes --no-install-recommends wget openssl && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apt/archives/*.deb && \
  wget --no-check-certificate https://downloads.mongodb.com/compass/mongodb-mongosh_${VERSION}_amd64.deb -O /tmp/mongosh.deb && \
  dpkg -i /tmp/mongosh.deb

ENTRYPOINT ["mongosh"]