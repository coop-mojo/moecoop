FROM frolvlad/alpine-glibc:latest
LABEL maintainer="Mojo"

RUN apk add --no-cache --virtual devtools perl curl git gcc make libc-dev && \
    touch /usr/local/bin/nkf && \
    chmod +x /usr/local/bin/nkf && \
    curl -o cmigemo.zip http://files.kaoriya.net/cmigemo/cmigemo-default-win64-20110227.zip && \
    unzip cmigemo.zip && \
    install -d /usr/share/migemo/utf-8 && \
    install -c -D -m 644 cmigemo-default-win64/dict/utf-8/* /usr/share/migemo/utf-8 && \
    rm -rf cmigemo.zip cmigemo-default-win64 && \
    git clone https://github.com/koron/cmigemo.git && \
    cd cmigemo && \
    ./configure --prefix=/usr && \
    make gcc && \
    make -f compile/Make_gcc.mak install-lib && \
    cd / && \
    rm -rf cmigemo /usr/local/bin/nkf && \
    apk del devtools && \
    apk add --no-cache libevent

ADD moecoop.tgz /moecoop

WORKDIR /moecoop

EXPOSE 8080

ENTRYPOINT ["./fukurod"]
