FROM alpine:latest

RUN apk update && apk upgrade && \
    apk add --no-cache \
    openssh

CMD mkdir -p /state/keys/web /state/keys/worker /state/postgres/pgdata && \
  ssh-keygen -t rsa -f /state/keys/web/tsa_host_key -N '' && \
  ssh-keygen -t rsa -f /state/keys/web/session_signing_key -N '' && \
  ssh-keygen -t rsa -f /state/keys/worker/worker_key -N '' && \
  cp /state/keys/worker/worker_key.pub /state/keys/web/authorized_worker_keys && \
  cp /state/keys/web/tsa_host_key.pub /state/keys/worker
