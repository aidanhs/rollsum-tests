FROM ubuntu:18.04
RUN apt-get update && \
    apt-get install -y gcc=4:7.3.0-3ubuntu2 curl git make bc bsdmainutils python-dev time # bsdmainutils for 'column'
RUN curl -sSL https://dl.google.com/go/go1.13.5.linux-amd64.tar.gz | tar -C /usr/local -xz
ENV PATH=$PATH:/usr/local/go/bin
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN . $HOME/.cargo/env && \
    rustup update 1.40.0 && \
    rustup default 1.40.0
ENV PATH=$PATH:/root/.cargo/bin:$PATH
WORKDIR /work
