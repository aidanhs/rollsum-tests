FROM ubuntu:14.04.3
RUN apt-get update && \
	apt-get install -y gcc=4:4.8.2-1ubuntu6 curl
RUN curl -O https://storage.googleapis.com/golang/go1.6.linux-amd64.tar.gz && \
	tar -C /usr/local -xzf go1.6.linux-amd64.tar.gz && \
	rm go1.6.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
RUN apt-get install -y git
RUN curl -sf https://raw.githubusercontent.com/brson/multirust/master/blastoff.sh | sh -s -- --yes && \
	multirust update 1.7.0 && \
	multirust default 1.7.0
RUN apt-get install -y make bc bsdmainutils python-dev
WORKDIR /work
