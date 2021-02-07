# Terraform Examples

Learning Networking and other concepts in cloud providers using terraform

Using terraform 0.14.5

Include the access/secret key before each run for each project. To get these:

1. Go to IAM service
2. Click on "Users" in the left sidebar
3. Click on your user (e.g. `cloud_user`)
4. Click on "Security credentials" tab
5. Click on "Create access key"
6. Copy the access key and secret and use it as an env variable as shown below

```
terraform init
AWS_ACCESS_KEY_ID=SET AWS_SECRET_ACCESS_KEY=SET terraform plan
AWS_ACCESS_KEY_ID=SET AWS_SECRET_ACCESS_KEY=SET terraform apply
```
