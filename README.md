# Mysfits All-in-One

This repo provides an all in one deployment of aws's modern application workshop [Mythical Mysfits](https://github.com/aws-samples/aws-modern-application-workshop).

Specifically this repo will deploy all modules (1-7) of the python-cdk branch with minor alterations.
**The 7th module will need manual editing in order to become functional. Please follow the module-7 instructions to set REPLACE_ME_SAGEMAKER_ENDPOINT in the lambda-recommendations service**

# Setup
_We will assume that you have an aws profile setup. Specific profiles can be specified by passing `--profile=profile_name` to any cdk command._
1. Install aws-cdk. `npm install -g aws-cdk`
2. Install dependancies. `cd cdk && npm i`
3. Bootstrap cdk if you have never done so. `cdk bootstrap`
4. Create an ecs service role if you have never done so. `aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com`
5. Ensure docker is installed locally.
6. Ensure your `AWS_PROFILE` environmental variable is set if you want to run scripts.

# Quickstart
## Creation
To deploy all modules 1-6 (and infrastructure for 7), load test data, and enable user self-registration run the following. Ensure `AWS_PROFILE` is set.
```shell
$ export AWS_PROFILE="<your profile name>"
$ export CONTACT_EMAIL="<your email address>"  # Optional, defaults to none@example.com (See cdk/lib/xray-stack.ts:65)
$ scripts/up.sh
```

## Deletion
The stack can be deleted by running
```shell
$ scripts/teardown.sh
```

# Manual Deployment
## Creation
Stack creation takes approximately 35 minutes.

The infrastructure definition is entirely handled by cdk, however containers still need to be manually built and pushed to ecr.

### Creating the stack
This stack can be simply deployed as follows.
```shell
$ cd cdk
$ cdk deploy '*'
```
This will generate interactive prompts asking you to confirm the creation of some resources. To avoid this you can specify the `--require-approval never` flag.
```shell
$ cdk deploy --require-approval never '*'
```

### Building and pushing the container
The code container needs to be manually built and pushed *after* the ecr resource has been deployed. This typically only takes 2-3 minutes after initiation of deployment.

The following steps can be automatically executed with `scripts/build_container.sh`.

Before building we setup some variables for convinience
```
$ cd assets/app
$ mm_aws_accountid=$(aws sts get-caller-identity --query Account --output text)
$ mm_aws_region=$(aws configure get region)
$ mm_container_name="mythicalmysfits/service"
```

The container can be built and tagged with
```shell
$ cd assets/app
$ docker build -t $mm_container_name .
$ docker tag $mm_container_name:latest $mm_aws_accountid.dkr.ecr.$mm_aws_region.amazonaws.com/$mm_container_name:latest
```

Next we can sign-in to the ecr registry and push our image
```shell
$ aws ecr get-login-password --region $mm_aws_region | docker login --username AWS --password-stdin $mm_aws_accountid.dkr.ecr.$mm_aws_region.amazonaws.com
$ aws ecr push $mm_aws_accountid.dkr.ec.$mm_aws_region.amazonaws.com/$mm_container_name:latest
```

### Finishing Up Deployment
Now the infrastrcture exists we will need to fix up some REPLACE_MEs in the environment. This can be done by running
```shell
$ scripts/postinstall.sh
```
To load test data and allow unmoderated signup run the following
```shell
$ scripts/load_test_env.sh
```

## Deletion
Stack deletion takes approximately 25 minutes.

Running `cdk destroy` is adequate to teardown a majority of the infrastructure. There are however a few resources that will need to be manually deleted.

_Note: cli assumes aws-cli v2_
| Parent Stack    | Resource                                         | Console                                                  | CLI |
| --------------- | ------------------------------------------------ | -------------------------------------------------------- | --- |
| KinesisFirehose | kinesisfirehose-bucket                           | S3 > _Select bucketname_ > Delete                        | `aws s3 rb s3://mythicalmysfits-kinesisfirehose-bucket<uniq>-<uniq>` |
| CICD            | cicd-pipelineartifactsbucket                     | S3 > _Select bucketname_ > Delete                        | `aws s3 rb s3://mythicalmysfits-cicd-pipelineartifactsbucket<uniq>-<uniq>` |
| ECS             | ECS-ServiceTaskDefMythical<wbr>MysfitsServiceLogGroup | CloudWatch > Log groups > _Select loggroupname_ > Delete | `aws logs delete-log-group --log-group-name MythicalMysfits-ECS-ServiceTaskDefMythicalMysfitsServiceLogGroup<uniq>-<uniq>` |
| XRay            | MysfitsQuestionsTable                            | DynamoDB > _Select tablename_ > Delete Table             | `aws dynamodb delete-table --table-name MysfitsQuestionsTable` |
| Website         | website-bucket                                   | S3 > _Select bucketname_ > Delete                        | `aws s3 rb s3://mythicalmysfits-website-bucket<uniq>-<uniq>` |
| ECR             | mythicalmysfits/service                          | ECR > _Select repositoryname_ > Delete                   | `aws ecr delete-repository --repository-name mythicalmysfits/service --force` |
| DynamoDB        | MysfitsTable                                     |  DynamoDB > _Select tablename_ > Delete Table            | `aws dynamodb delete-table --table-name MysfitsTable` |


# Changes
There are a few changes compared to the upstream vesion.

1. The dockerfile (`/assets/app/Dockerfile`) has been changed to install `python3-*`. References to `pip` have been changed to `pip3` and the entrypoint modified to `python3`.
2. Some instructional commands have been adapted to AWS-CLI v2 (namely those involved in signing to ecr).
3. A helper function has been introduced to the cdk stacks in order to normalize references to assets.
4. Changed some depreceated code to more mdoern versions (i.e. `lambda.Code.asset` -> `lambda.Code.fromAsset`)