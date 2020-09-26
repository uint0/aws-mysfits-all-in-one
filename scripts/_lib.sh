#!/bin/bash

function get_mm_stack_arn() {
    aws cloudformation list-stacks \
      --output text \
      --query 'sort_by(StackSummaries[?StackName==`MythicalMysfits-'$1'`]|[?StackStatus==`CREATE_COMPLETE`], &CreationTime)[-1].StackId'
}

function get_mm_stack_output() {
    aws cloudformation describe-stacks \
      --output text \
      --stack-name $1 \
      --query 'Stacks[0].Outputs[?OutputKey==`'$2'`].OutputValue'
}

function get_mm_stack_resource() {
    aws cloudformation list-stack-resources \
      --output text \
      --stack-name $1 \
      --query 'StackResourceSummaries[?ResourceType==`'$2'`]|[?starts_with(LogicalResourceId,`'$3'`)].PhysicalResourceId'
}