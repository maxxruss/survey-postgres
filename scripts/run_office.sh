#!/bin/bash

####################################### Boilerplate begin #######################################

# Detect where script SOURCE is located
# SCRIPT_ORIGPATH=`readlink -f "$(test -L "$0" && readlink "$0" || echo "$0")"`
# SCRIPT_ORIGDIR=`dirname $SCRIPT_ORIGPATH`

# . $SCRIPT_ORIGDIR/config.sh || eval 'echo "Could not source config file" 1>&2; exit 1'
# [ -z "$CONTAINERS_ROOT" ] && eval 'echo "CONTAINERS_ROOT" not set" 1>&2; exit 1'

# [ -z "$1" ] && eval 'echo "No argument supplied" 1>&2; exit 1'
# CONTAINER=$1

# CONTAINER_DIR="$CONTAINERS_ROOT/$CONTAINER"
# CONTAINER_CONFIG_DIR="$CONTAINER_DIR/config"

CONTAINER_DIR="../"
CONTAINER_CONFIG_DIR="$CONTAINER_DIR/config"

[ -d "$CONTAINER_DIR" ] || eval 'echo "Directory CONTAINER_DIR=$CONTAINER_DIR does not exist" 1>&2; exit 1'
[ -d "$CONTAINER_CONFIG_DIR" ] || eval 'echo "Directory CONTAINER_CONFIG_DIR=$CONTAINER_CONFIG_DIR does not exist" 1>&2; exit 1'

# Include container config
. $CONTAINER_CONFIG_DIR/container.cfg || eval 'echo "Could not source container config file" 1>&2; exit 1'

####################################### Boilerplate end #######################################

# If network not created
if [ "$NETWORK" != "" ] ; then
    NET_EXISTS=$(docker network ls | grep -c "$NETWORK")
    if [ "$NET_EXISTS" == "0" ] ; then
        docker network create -o com.docker.network.bridge.enable_ip_masquerade=false "$NETWORK"
    fi
fi

# Get current image tag
CURRENT_TAG=`cat $CONTAINER_CONFIG_DIR/$CURRENT_TAG_FILE`

# full image name, used when starting container
MY_IMAGE="$MY_IMAGE_NAME:$CURRENT_TAG"

docker pull "$MY_IMAGE"

docker run \
    --name ${MYSERVICE} \
    --hostname ${MYHOSTNAME} \
    -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    -e POSTGRES_DB=${POSTGRES_DB} \
    -e POSTGRES_USER=${POSTGRES_USER} \
    -v ${DATA_DIR_OFFICE}:/var/lib/postgresql \
    --network=${NETWORK} \
    -p 5432:5432 \
    ${MY_IMAGE}

# Attach container to networks needed
for NET_ATTACH in $NETWORK_ATTACH ; do
    docker network connect  $NET_ATTACH $MYSERVICE
done

docker start -a $MYSERVICE
