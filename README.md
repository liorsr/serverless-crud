# Serverless CRUD

## Requirements

* AWS account
* [AWS CLI](https://aws.amazon.com/cli/)
* [Terraform](https://developer.hashicorp.com/terraform/install)
* Python 3 (3.9+)

## Setup

1. Ensure required tools are installed (list above)
2. [Configure AWS account credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration) for Terraform
3. (Optional) Create a virtual environment for Python (e.g. venv, virtualenvwrapper, etc.)
4. Build and deploy
   * Run 'build_and_deploy' script (bash)
   * *OR* run the following commands in order
      1. `python3 scripts/deployment_prep.py`
      2. `terraform init` - Initialise config
      3. `terraform plan` - Prepare execution plan
      4. `terraform apply` - Apply changes to resources
5. Update payload format version for API Gateway integration - This fixes a known issue
described below
   1. Go to [API Gateway](console.aws.amazon.com/apigateway) in AWS Console
   2. Navigate to your CRUD API (`serverless-crud-api`)
   3. Go to `Develop > Integrations`
   4. Open `Manage integrations` tab
   5. Select integration (`serverless-crud-function`)
   6. Click `Edit`
   7. Under `Integration details`, expand `Advanced settings`
   8. Change `Payload format version` value to `2.0`
   9. Save changes
  
\* The build script will output API and website URL. The website simply allows to view created
items.

## Clean-up

Run `terraform destroy` to destroy all resources defined in configuration.
destroy

## Test

You will find a few curl commands under `scripts/test_crud.sh` that allow testing the API functionality.

You may view the current state of the items on associated website (URL found in build script
output).

## Known Issues

* The API Gateway integration created by Terraform sets its payload format version to `1.0` by
default. Explicitly setting it to `2.0` (as required by lambda) in Terraform config causes
server error. This can be fixed by setting it manually after the fact in the AWS Console (see
[setup](#setup) steps). Though, it should be fixed, as it requires a manual step after every
integration resource update.

## Next Steps

- [ ] Check infrastructure security
- [ ] Fix [known issues](#known-issues)
- [ ] Add unit tests for lambda operations
- [ ] Improve error handling, logging
- [ ] Enable CloudWatch
- [ ] Add CRUD operations to website
