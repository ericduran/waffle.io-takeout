#!/bin/bash

blue='\033[0;34m'
red='\033[0;31m'
reset='\033[0m'

hash docker 2>/dev/null || { echo -e >&2 "${red}I require docker but it's not installed.  Aborting.${reset}"; exit 1; }

if [ ! $WAFFLE_AWS_ACCESS_KEY_ID ]
then
  echo -e "${red}You must supply an environment variable named $WAFFLE_AWS_ACCESS_KEY_ID set to your AWS access key.${reset}"
  exit 1
fi

if [ ! $WAFFLE_AWS_SECRET_ACCESS_KEY ]
then
  echo -e "${red}You must supply an environment variable named $WAFFLE_AWS_SECRET_ACCESS_KEY set to your AWS secret.${reset}"
  exit 1
fi

if [ $WAFFLE_QUAYIO_USERNAME ] && [ $WAFFLE_QUAYIO_PASSWORD ] && [ $WAFFLE_QUAYIO_EMAIL ]
then
  echo -e "\n${blue}Logging in to quay.io${reset}"
  docker login -u $WAFFLE_QUAYIO_USERNAME -p $WAFFLE_QUAYIO_PASSWORD -e $WAFFLE_QUAYIO_EMAIL quay.io
else
  echo -e "\n${blue}Please login to quay.io${reset}"
  docker login quay.io
fi

mkdir waffleio-takeout
mkdir waffleio-takeout/ca-certificates

echo -e "\nPulling images from quay.io..."
docker pull quay.io/waffleio/hedwig
docker pull quay.io/waffleio/poxa
docker pull quay.io/waffleio/waffle.io-app
docker pull quay.io/waffleio/waffle.io-hooks
docker pull quay.io/waffleio/waffle.io-migrations
docker pull quay.io/waffleio/waffle.io-rally-integration
docker pull quay.io/waffleio/waffle.io-admin

docker save --output="waffleio-takeout/hedwig.tar" quay.io/waffleio/hedwig
docker save --output="waffleio-takeout/poxa.tar" quay.io/waffleio/poxa
docker save --output="waffleio-takeout/waffle.io-app.tar" quay.io/waffleio/waffle.io-app
docker save --output="waffleio-takeout/waffle.io-hooks.tar" quay.io/waffleio/waffle.io-hooks
docker save --output="waffleio-takeout/waffle.io-migrations.tar" quay.io/waffleio/waffle.io-migrations
docker save --output="waffleio-takeout/waffle.io-rally-integration.tar" quay.io/waffleio/waffle.io-rally-integration
docker save --output="waffleio-takeout/waffle.io-admin.tar" quay.io/waffleio/waffle.io-admin

cp install.sh waffleio-takeout/
cp waffleio-env.list waffleio-takeout/

echo "Packaging files together"
timestamp="$(date +"%Y-%m-%d-%H:%M:%S")"
if [ $1 ]
then
  suffix="-${1}"
else
  suffix=""
fi
filename="waffleio-takeout-${timestamp}${suffix}.zip"
zip -r $filename waffleio-takeout

rm -rf waffleio-takeout/

./upload.sh $filename

echo 'Finished'
