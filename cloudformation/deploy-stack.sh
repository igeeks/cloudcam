#!/usr/bin/env bash

STACK_NAME=cloudcamdev         # stack name
S3_CODE_BUCKET=cloudcam-code   # s3 bucket to upload lambda code to, will be created if doesn't exist
S3_UI_BUCKET=${STACK_NAME}-ui  # ui bucket

MODE=${1:-update}              # create or update

aws s3 mb s3://${S3_CODE_BUCKET}
aws cloudformation package --template-file cloudcam.yml --s3-bucket ${S3_CODE_BUCKET} --output-template-file cloudcam-packaged.yml
aws cloudformation ${MODE}-stack --template-body file://cloudcam-packaged.yml --stack-name ${STACK_NAME} --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
( cd ../dev-ui && NODE_ENV=production webpack )
aws s3 cp --recursive --acl public-read ../dev-ui/webroot s3://${S3_UI_BUCKET}
