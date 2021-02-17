FROM golang:1.14 as builder
WORKDIR /
RUN git clone https://github.com/gohornet/hornet.git
WORKDIR /hornet
RUN ./scripts/build_hornet.sh

FROM debian:stable
USER root
COPY --from=builder /hornet/hornet /usr/bin/hornet
ENTRYPOINT ["/usr/bin/hornet"]
