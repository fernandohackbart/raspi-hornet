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

## Running private tangle (with MQTT enabled service) with single node in Raspberry PI

Using the [documentation](https://docs.iota.org/docs/hornet/1.1/tutorials/set-up-a-private-tangle-hornet) from IOTA

The steps were adapted to use podman on RaspberryPI

## Create directory structure and configuration files
Prepare run folder with the directories and configuration files (using the default ons from the Hornet project)
```bash
mkdir -p /opt/hornet/db
cd /opt/hornet
```

### Create configuration files

```bash
cat > mqtt_config.json <<EOF
{
  "workerNum": 4096,
  "port": "1883",
  "host": "0.0.0.0",
  "cluster": {
    "host": "",
    "port": ""
  },
  "router": "",
  "wsPort": "",
  "wsPath": "/ws",
  "wsTLS": false,
  "tlsPort": "",
  "tlsHost": "",
  "tlsInfo": {
    "verify": false,
    "caFile": "tls/ca/cacert.pem",
    "certFile": "tls/server/cert.pem",
    "keyFile": "tls/server/key.pem"
  },
  "plugins": {}
}
EOF

cat > config.json <<EOF
{
  "coordinator": {
    "merkleTreeDepth": 16,
    "mwm": 5,
    "stateFilePath": "db/coordinator.state",
    "merkleTreeFilePath": "db/coordinator.tree",
    "intervalSeconds": 60,
    "checkpointTransactions": 5
  },
  "db":{
    "path": "db"
  },  
  "snapshots": {
    "loadType": "global",
    "global": {
      "path": "snapshot.csv",
      "spentAddressesPaths": [],
      "index": 0
    }
  },  
  "useProfile": "auto",
  "httpAPI": {
    "basicAuth": {
      "enabled": false,
      "username": "",
      "passwordHash": "",
      "passwordSalt": ""
    },
    "excludeHealthCheckFromAuth": false,
    "permitRemoteAccess": [
      "getNodeInfo",
      "getBalances",
      "checkConsistency",
      "getTipInfo",
      "getTransactionsToApprove",
      "getInclusionStates",
      "getNodeAPIConfiguration",
      "wereAddressesSpentFrom",
      "broadcastTransactions",
      "findTransactions",
      "storeTransactions",
      "getTrytes"
    ],
    "permittedRoutes": [
      "healthz"
    ],
    "whitelistedAddresses": [],
    "bindAddress": "0.0.0.0:14265",
    "limits": {
      "bodyLengthBytes": 1000000,
      "findTransactions": 1000,
      "getTrytes": 1000,
      "requestsList": 1000
    }
  },
  "dashboard": {
    "bindAddress": "0.0.0.0:8081",
    "theme": "default",
    "basicAuth": {
      "enabled": false,
      "username": "",
      "passwordHash": "",
      "passwordSalt": ""
    }
  },
  "spentAddresses": {
    "enabled": true
  },
  "network": {
    "preferIPv6": false,
    "gossip": {
      "bindAddress": "0.0.0.0:15600",
      "reconnectAttemptIntervalSeconds": 60
    },
    "autopeering": {
      "bindAddress": "0.0.0.0:14626",
      "runAsEntryNode": false,
      "seed": ""
    }
  },
  "node": {
    "alias": "Coordinator",
    "showAliasInGetNodeInfo": false,
    "disablePlugins": [],
    "enablePlugins": [
      "Coordinator",
      "MQTT"
    ]
  },
  "logger": {
    "level": "info",
    "disableCaller": true,
    "encoding": "console",
    "outputPaths": [
      "stdout"
    ]
  },
  "spammer": {
    "address": "HORNET99INTEGRATED99SPAMMER999999999999999999999999999999999999999999999999999999",
    "message": "Spamming with HORNET tipselect",
    "tag": "HORNET99INTEGRATED99SPAMMER",
    "tagSemiLazy": "",
    "cpuMaxUsage": 0.8,
    "tpsRateLimit": 0.0,
    "bundleSize": 1,
    "valueSpam": false,
    "workers": 0,
    "autostart": false
  },
  "zmq": {
    "bindAddress": "localhost:5556"
  },
  "profiling": {
    "bindAddress": "localhost:6060"
  },
  "prometheus": {
    "bindAddress": "localhost:9311",
    "goMetrics": false,
    "processMetrics": false,
    "promhttpMetrics": false
  }
}
EOF
```

Change the permissions to the hornet user:
```bash
podman unshare chown 39999:39999 /opt/hornet/*
```

### Generate seed an Merkle tree

Generate seed
```bash
cat /dev/urandom |LC_ALL=C tr -dc 'A-Z9' | fold -w 81 | head -n 1
```

Generate Merkle tree
```bash
podman run -it\
 -u 39999\
 -e COO_SEED=XUEQOQHHSQRCTMFIGKEMVOE9ONZGDXOOVFA99MSFRJPRBUIDBPCGOXFOECSYQADVDXBO9MCZCRODGBUTA \
 -v /opt/hornet/config.json:/app/hornet/config.json:ro\
 -v /opt/hornet/db:/app/hornet/db\
 fernandohackbart/raspi-hornet:0.5.6-0715a16 hornet tool merkle
```

Add the `merkle tree root:` result as the coordinator address in the configuration

Example:
```json
{
  "coordinator": {
    "address": "VYBAMRZTRESLNFCXTOGRRODW9PKWASNBMXUFXNRQNI9GWHRHDDWHIZEATFROXAPMESETELNODTF9GIQTX",
    ...
  }
}
```

### Create snapshot

#### Create new seed

```bash
cat /dev/urandom |LC_ALL=C tr -dc 'A-Z9' | fold -w 81 | head -n 1 
```

Example
```
GUEOTSEITFEVEWCWBTSIZM9NKRGJEIMXTULBACGFRQK9IMGICLBKW9TTEVSDQMGWKBXPVCBMMCXWMNPDX
```

#### Create new address (the initial address of the tangle)

From [github.com/iotaledger/one-click-tangle](https://github.com/iotaledger/one-click-tangle)

```bash
docker-compose run --rm -w /usr/src/app address-generator sh -c 'npm install --prefix=/package "@iota/core" > /dev/null && node address-generator.js $(cat node.seed) 2> /dev/null > address.txt'
```

The address for the example seed
```
HYHSSNWMLOSRLV9ULBYTAFVQUPZLBKAGSRJOVD9X9MBELPKNMX9SWKFNYGBHQVCHLXKRIRNOAUD9MPNCW
```

#### Create snapshot.csv

```bash
cat > snapshot.csv <<EOF
HYHSSNWMLOSRLV9ULBYTAFVQUPZLBKAGSRJOVD9X9MBELPKNMX9SWKFNYGBHQVCHLXKRIRNOAUD9MPNCW;2779530283277761
EOF
```

### Boostrap the tangle

```bash
podman run -it\
 -u root\
 -e COO_SEED=XUEQOQHHSQRCTMFIGKEMVOE9ONZGDXOOVFA99MSFRJPRBUIDBPCGOXFOECSYQADVDXBO9MCZCRODGBUTA\
 -v /opt/hornet/config.json:/app/hornet/config.json:ro\
 -v /opt/hornet/snapshot.csv:/app/hornet/snapshot.csv:ro\
 -v /opt/hornet/mqtt_config.json:/app/hornet/mqtt_config.json:ro\
 -v /opt/hornet/db:/app/hornet/db:Z\
 fernandohackbart/raspi-hornet:0.5.6-0715a16 --cooBootstrap
```

Cancel execution with `CTRL-C` when the first milstone is issued.

### Run the node

```bash
podman run -d\
 --name iota-hornet\
 --restart always\
 -u root\
 -p 1883:1883\
 -p 8081:8081\
 -e COO_SEED=XUEQOQHHSQRCTMFIGKEMVOE9ONZGDXOOVFA99MSFRJPRBUIDBPCGOXFOECSYQADVDXBO9MCZCRODGBUTA\
 -v /opt/hornet/config.json:/app/hornet/config.json:ro\
 -v /opt/hornet/mqtt_config.json:/app/hornet/mqtt_config.json:ro\
 -v /opt/hornet/snapshot.csv:/app/hornet/snapshot.csv:ro\
 -v /opt/hornet/db:/app/hornet/db:Z\
 fernandohackbart/raspi-hornet:0.5.6-0715a16
```
