*** Concourse on ECS ***

Terraform module to run Dockerized Concourse CI on Amazon ECS.

Note that this uses only ephemeral storage so any change in the underlying EC2 Instances will result in a loss of data.

You will need a terraform.tfvars file. See the ./terraform.tfvars.example
