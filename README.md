# zeronorth-cloud-platforms-coding-challenge-solution

My solution to [this coding challenge](https://github.com/0north/cloud-platforms-coding-challenge).

## Setup

### S3 storage

The S3 storage is expected to receive JSON data files that contains a single
list of integers per JSON file.

### Lambda function

The lambda function is invoked when events are created from new file uploads
to the S3 storage.

The lambda function retrieves the JSON data file, unmarshals it and sums
up the integers.

The result of the summation is logged and can be viewed in the given log group
in CloudWatch.

## Prerequisites

### AWS account and Terraform user

In order to deploy infrastructure on AWS you need to have an AWS root account
wherein you create a Terraform user.

To get this project working, I have created a 'terraform' user with the following 
permission policies added to it:

- `CloudWatchFullAccess`
- `AmazonS3FullAccess`
- `AWSLambda_FullAccess`
- `IAMFullAccess`

### Tooling needed

You need the following tools on your dev computer:

- `aws` CLI tool. You need to run `aws configure` and input the given access
  information that you got from creating the `terraform` user
- `terraform` CLI tool. Any recent version is presumably working
- `bash`: the `test.sh` script assumes that you're working on a Linux/MacOS
   machine.

## Deploying infrastructure and application

To deploy the complete application you need to open your terminal in the
repository root directory and execute the following commands:

```sh
terraform init
terraform plan
terraform apply
```

## E2E testing

To test that the infra/application is working you can perform an end-to-end
test by running the following bash script:

```sh
./test.sh
```

## Cleaning up

When you are finished using the deployed application, ensure that you
destroy the infrastructure as not to incur any unnecessary costs:

```sh
terraform destroy
```
