#!/bin/bash
PROJECT_NAME=paperqa
DOCKER_REGISTRY=YOUR_DOCKER_REGISTRY
IMAGE_VERSION=1

aws ecr get-login-password | docker login --username AWS --password-stdin $DOCKER_REGISTRY
docker build \
-t $DOCKER_REGISTRY/$PROJECT_NAME:$IMAGE_VERSION \
-t $DOCKER_REGISTRY/$PROJECT_NAME:latest .
docker push $DOCKER_REGISTRY/$PROJECT_NAME:$IMAGE_VERSION
docker push $DOCKER_REGISTRY/$PROJECT_NAME:latest