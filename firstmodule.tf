##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {
  default = "terraform-key"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
  version    = "1.43.2"
}

##################################################################################
# RESOURCES
##################################################################################

resource "aws_instance" "nginx" {
  ami           = "ami-c58c1dd3"
  instance_type = "t2.micro"
  key_name        = "${var.key_name}"

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
    agent       = "false"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start"
    ]
  }
}

data "template_file" "swagger_api" {
  template = "${file("swagger/PetStore-dev-swagger-apigateway.json")}"
}

resource "aws_api_gateway_rest_api" "MyPetStoreAPI" {
  name = "MyTerraformAPI"
  description = "This is my API for demonstration purposes"
  body = "${data.template_file.swagger_api.rendered}"
}

resource "aws_api_gateway_deployment" "MyDemoDeployment" {
  depends_on = ["aws_api_gateway_rest_api.MyPetStoreAPI"]

  rest_api_id = "${aws_api_gateway_rest_api.MyPetStoreAPI.id}"
  stage_name  = "test"

  variables = {
    "answer" = "42"
  }
}
##################################################################################
# OUTPUT
##################################################################################

output "aws_instance_public_dns" {
    value = "${aws_instance.nginx.public_dns}"
}

output "aws_api_url" {
    value = "${aws_api_gateway_deployment.MyDemoDeployment.invoke_url}"
}

