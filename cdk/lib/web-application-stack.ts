import cdk = require("@aws-cdk/core");
import cloudfront = require("@aws-cdk/aws-cloudfront");
import iam = require("@aws-cdk/aws-iam");
import s3 = require("@aws-cdk/aws-s3");
import s3deploy = require("@aws-cdk/aws-s3-deployment");
import assetLoader = require("../utils/assets");
import apigateway = require('@aws-cdk/aws-apigateway');
import cognito = require("@aws-cdk/aws-cognito");
import fs = require("fs");

interface WebAppStackProps extends cdk.StackProps {
  apiGateway: apigateway.CfnRestApi;
  userPool: cognito.UserPool;
  userPoolClient: cognito.UserPoolClient
}

export class WebApplicationStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props: WebAppStackProps) {
    super(scope, id);

    // Obtain the content directory from CDK context
    const webAppRoot = assetLoader.getAssetPath('web');
    /*this.patchWebApp(webAppRoot, {
      apiEndpoint: `https://${props.apiGateway.ref}.execute-api.${this.region}.amazonaws.com/prod/`,
      cognitoUserPool: props.userPool.userPoolId,
      cognitoClientId: props.userPoolClient.userPoolClientId
    });*/

    // Create a S3 bucket, with the given name and define the web index document as 'index.html'
    const bucket = new s3.Bucket(this, "Bucket", {
      websiteIndexDocument: "index.html"
    });

    // Obtain the cloudfront origin access identity so that the s3 bucket may be restricted to it.
    const origin = new cloudfront.OriginAccessIdentity(this, "BucketOrigin", {
        comment: "mythical-mysfits"
    });

    // Restrict the S3 bucket via a bucket policy that only allows our CloudFront distribution
    bucket.grantRead(new iam.CanonicalUserPrincipal(
      origin.cloudFrontOriginAccessIdentityS3CanonicalUserId
    ));

    // Definition for a new CloudFront web distribution, which enforces traffic over HTTPS
    const cdn = new cloudfront.CloudFrontWebDistribution(this, "CloudFront", {
      viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.ALLOW_ALL,
      priceClass: cloudfront.PriceClass.PRICE_CLASS_ALL,
      originConfigs: [
        {
          behaviors: [
            {
              isDefaultBehavior: true,
              maxTtl: undefined,
              allowedMethods:
                cloudfront.CloudFrontAllowedMethods.GET_HEAD_OPTIONS
            }
          ],
          originPath: `/web`,
          s3OriginSource: {
            s3BucketSource: bucket,
            originAccessIdentity: origin
          }
        }
      ]
    });

    // A CDK helper that takes the defined source directory, compresses it, and uploads it to the destination s3 bucket.
    new s3deploy.BucketDeployment(this, "DeployWebsite", {
      sources: [
        s3deploy.Source.asset(webAppRoot)
      ],
      destinationKeyPrefix: "web/",
      destinationBucket: bucket,
      distribution: cdn,
      distributionPaths: [ '/index.html' ],
      retainOnDelete: false
    });

    // Create a CDK Output which details the URL for the CloudFront Distribtion URL.
    new cdk.CfnOutput(this, "CloudFrontURL", {
      description: "The CloudFront distribution URL",
      value: "http://" + cdn.distributionDomainName
    });
  }

  private patchWebApp(root: string, params: {apiEndpoint: string, cognitoClientId: string, cognitoUserPool: string}): void {
    const template = assetLoader.getTemplatePath(`web/config.template.js`);
    const outfile  = `${root}/js/config.js`;
    const content = fs.readFileSync(template).toString()
                        .replace(/REPLACE_ME_API_ENDPOINT/g, params.apiEndpoint)
                        .replace(/REPLACE_ME_COGNITO_USER_POOL/g, params.cognitoUserPool)
                        .replace(/REPLACE_ME_COGNITO_CLIENT_ID/g, params.cognitoClientId)
                        .replace(/REPLACE_ME_AWS_REGION/, this.region);
    fs.writeFileSync(outfile, content);
  }
}
