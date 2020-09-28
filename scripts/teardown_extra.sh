#!/bin/bash

function get_mm_deleted_stack_id() {
    aws cloudformation list-stacks \
      --output text \
      --query 'sort_by(StackSummaries[?StackName==`MythicalMysfits-'$1'`]|[?StackStatus==`DELETE_COMPLETE`], &DeletionTime)[-1].StackId'
}

function query_orphaned_resource() {
    aws cloudformation list-stack-resources \
      --output text \
      --stack-name $1 \
      --query 'StackResourceSummaries[?ResourceStatus==`DELETE_SKIPPED`]|[?starts_with(LogicalResourceId, `'$2'`)].PhysicalResourceId'
}

echo "Destroying Kinesis Resources"
stack_arn=$(get_mm_deleted_stack_id KinesisFirehose)
resource=$(query_orphaned_resource $stack_arn Bucket)
aws s3 rb s3://$resource

echo "Destroying CICD Resources"
stack_arn=$(get_mm_deleted_stack_id CICD)
resource=$(query_orphaned_resource $stack_arn PipelineArtifactsBucket)
aws s3 rb s3://$resource

echo "Deleting ECS Resources"
stack_arn=$(get_mm_deleted_stack_id ECS)
resource=$(query_orphaned_resource $stack_arn ServiceTaskDefMythicalMysfitsServiceLogGroup)
aws logs delete-log-group --log-group-name $resource

echo "Deleting XRay Resources"
stack_arn=$(get_mm_deleted_stack_id XRay)
resource=$(query_orphaned_resource $stack_arn Table)
aws dynamodb delete-table --table-name $resource

echo "Deleting Website Resources"
stack_arn=$(get_mm_deleted_stack_id Website)
resource=$(query_orphaned_resource $stack_arn Bucket)
aws s3 rb s3://$resource

echo "Deleting ECR Resources"
stack_arn=$(get_mm_deleted_stack_id ECR)
resource=$(query_orphaned_resource $stack_arn Repository)
aws ecr delete-repository --force --repository-name $resource

echo "Deleting DynamoDB Resources"
stack_arn=$(get_mm_deleted_stack_id DynamoDB)
resource=$(query_orphaned_resource $stack_arn Table)
aws dynamodb delete-table --table-name $resource
