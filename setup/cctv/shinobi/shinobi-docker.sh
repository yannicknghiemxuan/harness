#!/bin/bash
if ! [ -x "$(command -v docker)" ]; then
    echo "You are missing Docker"
    echo "docker not found!"
    echo "Get it here : https://docs.docker.com/engine/install/"
    exit 1
else
    docker -v
fi
if ! [ -x "$(command -v docker-compose)" ]; then
    echo "You are missing Docker Compose"
    echo "docker-compose not found!"
    echo "Get it here : https://docs.docker.com/compose/install/"
    exit 1
else
    docker-compose -v
fi

PLUGIN_LIST=''
PLUGIN_YMLS=();

SSL_TOGGLE="$(echo "$1" | awk '{print tolower($0)}')"
if [ "$SSL_TOGGLE" = "true" ]; then
    SSL_TOGGLE='true'
else
    SSL_TOGGLE='false'
fi

echo "Shinobi - Do you want to Install Object Detection? (TensorFlow.js)"
echo "(y)es or (N)o"
read -r TENSORFLOW_PLUGIN_DOCKER_ADDON_AGREE
TENSORFLOW_PLUGIN_DOCKER_ADDON_AGREE="$(echo "$TENSORFLOW_PLUGIN_DOCKER_ADDON_AGREE" | awk '{print tolower($0)}')"
if [ "$TENSORFLOW_PLUGIN_DOCKER_ADDON_AGREE" = "y" ]; then
    TENSORFLOW_PLUGIN_KEY=$(head -c 1024 < /dev/urandom | sha256sum | awk '{print substr($1,1,29)}')
    PLUGIN_YMLS+=('"Tensorflow":"'$TENSORFLOW_PLUGIN_KEY'"')
    PLUGIN_LIST+=$(cat <<-END

    shinobiplugintensorflow:
        image: shinobisystems/shinobi-tensorflow:latest
        container_name: shinobi-tensorflow
        environment:
          - PLUGIN_KEY=$TENSORFLOW_PLUGIN_KEY
          - PLUGIN_HOST=Shinobi
        volumes:
          - /shinobi/docker-plugins/tensorflow:/config
        restart: unless-stopped
END
    )
fi

# Join Plugin Keys
PLUGIN_YMLS=$(printf ",%s" "${PLUGIN_YMLS[@]}")
PLUGIN_YMLS=${PLUGIN_YMLS:1}
PLUGIN_YMLS="{$PLUGIN_YMLS}"
cat > docker-compose.yml <<- EOM
version: "3"
services:
    shinobi:
        image: shinobisystems/shinobi:dev
        container_name: Shinobi
        environment:
           - PLUGIN_KEYS=$PLUGIN_YMLS
           - SSL_ENABLED=$SSL_TOGGLE
        volumes:
           - /shinobi/config:/config
           - /shinobi/customAutoLoad:/home/Shinobi/libs/customAutoLoad
           - /shinobi/database:/var/lib/mysql
           - /shinobi/videos:/home/Shinobi/videos
           - /shinobi/plugins:/home/Shinobi/plugins
           - /dev/shm/Shinobi/streams:/dev/shm/streams
           - /etc/localtime:/etc/localtime:ro
        ports:
           - 8080:8080
        restart: unless-stopped
$PLUGIN_LIST
EOM
cat docker-compose.yml
docker-compose up -d
# rm docker-compose.yml
