# Building Hornet from source to container

To build a container that runs on Raspberry Pi podman, we will 

## Build the contianer

### Building with Docker

```bash
docker build . -t raspi-hornet
```

### Building with Buildah

```bash
buildah unshare ./buildah.sh 
```

### Pushing the image to Docker repo

```bash
docker login
export CONTAINER_TAG=`docker run raspi-hornet hornet --version | awk '{print $2;}'`
echo $CONTAINER_TAG
docker tag raspi-hornet fernandohackbart/raspi-hornet:$CONTAINER_TAG
docker push fernandohackbart/raspi-hornet:$CONTAINER_TAG
```

## Running the container

Prepare run folder with the directories and confguration files (using the default ons from the Hornet project)
```bash
cd /opt/stage/
sudo rm -rf /opt/stage/hornet
mkdir -p /opt/stage/hornet
cd /opt/stage/hornet
cp /home/fernando.hackbart/Documents/Projects/fernandohackbart/hornet/{config_devnet,mqtt_config,peering,profiles}.json /opt/stage/hornet/.
mv /opt/stage/hornet/config_devnet.json /opt/stage/hornet/config.json
mkdir -p snapshots/{mainnet,comnet,devnet} mainnetdb comnetdb devnetdb
sudo chown -R 39999:39999 /opt/stage/hornet 
```

Run the container 

```bash
docker run -it\
 -p 14265:14265\
 -p 15600:15600\
 -p 1883:1883\
 -v /opt/stage/hornet/config.json:/app/hornet/config.json:ro\
 -v /opt/stage/hornet/mqtt_config.json:/app/hornet/mqtt_config.json\
 -v /opt/stage/hornet/profiles.json:/app/hornet/profiles.json\
 -v /opt/stage/hornet/peering.json:/app/hornet/peering.json\
 -v /opt/stage/hornet/snapshots/mainnet:/app/hornet/snapshots/mainnet\
 -v /opt/stage/hornet/snapshots/comnet:/app/hornet/snapshots/comnet\
 -v /opt/stage/hornet/snapshots/comnet:/app/hornet/snapshots/devnet\
 -v /opt/stage/hornet/mainnetdb:/app/hornet/mainnetdb\
 -v /opt/stage/hornet/comnetdb:/app/hornet/devnetdb\
 -v /opt/stage/hornet/comnetdb:/app/hornet/comnetdb\
 raspi-hornet
```
