FROM golang:1.14 as builder
WORKDIR /
RUN git clone https://github.com/gohornet/hornet.git
WORKDIR /hornet
RUN ./scripts/build_hornet.sh
FROM debian:latest
USER root
RUN apt-get update && apt-get -y install ca-certificates && mkdir -p /app/hornet && useradd -d /app/hornet -s /bin/sh -u 39999 hornet && chown hornet:hornet /app/hornet
COPY --from=builder /hornet/hornet /app/hornet
USER hornet
WORKDIR /app/hornet
ENTRYPOINT ["/app/hornet/hornet"]
