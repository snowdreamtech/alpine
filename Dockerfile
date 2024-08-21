FROM alpine:3.20.2

LABEL maintainer="snowdream <sn0wdr1am@qq.com>"

# keep the docker container running
ENV KEEPALIVE=0

RUN echo "@main https://dl-cdn.alpinelinux.org/alpine/edge/main" | tee -a /etc/apk/repositories \
    && echo "@community https://dl-cdn.alpinelinux.org/alpine/edge/community" | tee -a /etc/apk/repositories \
    && echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" | tee -a /etc/apk/repositories \
    && apk add --no-cache musl-locales \
    musl-locales-lang \
    tzdata \
    openssl \
    wget \  
    ca-certificates \                                                                                                                                                                                                      
    && update-ca-certificates    

# ENTRYPOINT [ "sh", "-c", "trap : TERM INT; tail -f /dev/null & wait" ]
# ENTRYPOINT [ "sh", "-c", "trap : TERM INT; sleep infinity & wait" ]
# CMD [ "sh", "-c", "trap : TERM INT; tail -f /dev/null & wait" ]
# CMD [ "sh", "-c", "trap : TERM INT; sleep infinity & wait" ]