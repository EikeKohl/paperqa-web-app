ECS_CLUSTER_NAME=paperqa-cluster
ECS_SERVICE_NAME=paperqa-service
aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $ECS_SERVICE_NAME --force-new-deployment