#!/bin/bash
PROJECT_NAME: paperqa
DOCKER_REGISTRY: YOUR_AWS_DOCKER_REGISTRY
IMAGE_VERSION: 1
ECS_CLUSTER_NAME: paperqa-cluster
ECS_SERVICE_NAME: paperqa-service

aws ecr get-login-password | docker login --username AWS --password-stdin $DOCKER_REGISTRY
docker build \
-t $DOCKER_REGISTRY/$PROJECT_NAME:$IMAGE_VERSION \
-t $DOCKER_REGISTRY/$PROJECT_NAME:latest .
docker push $DOCKER_REGISTRY/$PROJECT_NAME:$IMAGE_VERSION
docker push $DOCKER_REGISTRY/$PROJECT_NAME:latest
aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $ECS_SERVICE_NAME --force-new-deployment