#!/bin/bash
buildcntr=$(buildah from golang:1.14)
buildmnt=$(buildah mount $buildcntr)
buildah run $buildcntr git clone https://github.com/gohornet/hornet.git
buildah run $buildcntr /bin/bash -c 'cd /go/hornet ; scripts/build_hornet.sh'
rtcntr=$(buildah from debian:latest)
rtmnt=$(buildah mount $rtcntr)
buildah run $buildcntr /bin/bash -c 'apt-get update && apt-get -y install ca-certificates && mkdir -p /app/hornet && useradd -d /app/hornet -s /bin/sh -u 39999 hornet && chown hornet:hornet /app/hornet'
cp $buildmn/go/hornet/hornet $rtmnt/app/hornet/hornet
buildah unmount $buildcntr
buildah rm $buildcntr
buildah config --user hornet $rtcntr
buildah config --workingdir /app/hornet $rtcntr
buildah config --cmd /app/hornet/hornet $rtcntr
buildah unmount $rtcntr
buildah commit $rtcntr raspi-hornet:latest
buildah rm $rtcntr
buildah containers
buildah images