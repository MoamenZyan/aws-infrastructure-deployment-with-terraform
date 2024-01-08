
/*
How to use:
Just update the path of the credentials files to yours
run the script.sh file

check the infratructure in the "eu-north-1" region
*/

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
    }
}

provider "aws" {
    region = "eu-north-1"
    shared_credentials_files = ["~/.aws/credentials"] # Very important to not hard code your credentials here
}
