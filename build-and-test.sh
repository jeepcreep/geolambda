#!/bin/bash

VERSION=3.0.1
PYVERSION=3.8.19

docker build . -t jeepcreep/geolambda:${VERSION}
docker run --rm -v $PWD:/home/geolambda -it jeepcreep/geolambda:${VERSION} package.sh

cd python
docker build . --build-arg VERSION=${VERSION} -t jeepcreep/geolambda:${VERSION}-python
docker run -v ${PWD}:/home/geolambda -t jeepcreep/geolambda:${VERSION}-python package-python.sh

docker run -e GDAL_DATA=/opt/share/gdal -e PROJ_LIB=/opt/share/proj \
    --rm -v ${PWD}/lambda:/var/task lambci/lambda:python3.8 lambda_function.lambda_handler '{}'
