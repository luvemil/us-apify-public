# us-apify-public

This project builds a function to be run on AWS Lambda and automatically releases it as part of the CI/CD pipeline.

You need access to a private repository in order to be able to build the whole project. However you can use this as an example on how to use AWS Lambda with Haskell.

## Local build

Build with

```
. .env
make
```

Run locally with

```
make run-local
```

and call the lambda with

```
curl -X POST http://localhost:9000/2015-03-31/functions/function/invocations -H 'Content-Type: application/json' -d '{"type":"SAVE", "payload": "<payload>"}'
```

## Build with git actions

The repository is configured to build a docker image containing the lambda, publish it to AWS ECR and call terraform cloud to update the lambda. The secrets that need to be configured are:

- `AWS_REGION`: the aws region where the ecr resides
- `AWS_ECR_IMAGE`: the name of the ecr
- `AWS_KEY_ID` and `AWS_SECRET_KEY`: the aws credentials
- `TF_TOKEN`: an api token generated on terraform cloud
- `TF_WORKSPACE`: the workspace on terraform cloud
