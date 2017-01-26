FROM ubuntu:latest
LABEL maintainer="Mojo"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --no-install-suggests --no-install-recommends -y \
            unzip cmigemo \
            libevent-2.0-5 libssl1.0.0 libevent-pthreads-2.0-5

ADD moecoop.zip /

RUN unzip /moecoop.zip -d moecoop && \
    apt-get purge -y unzip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

WORKDIR /moecoop

CMD ["./fukurod"]
