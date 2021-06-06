terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
# Credentials and default region are set on envrionment variables
provider "aws" {}

# Setting up master node
resource "aws_instance" "kube_master" {
  ami           = "ami-02e2a5679226e293c" # ID of default Debian 10 ami (64-bit|x86)
  instance_type = "t2.micro" # To keep it free tier eligible we will be using t2.micro
    Name = "kube-master"
  }
  key_name = "k8s-lab"

  provisioner "remote-exec" {
    connection {
      host = self.public_ip
      user = "admin"
      private_key = file("~/.ssh/k8s-lab.pem")
    }
    inline = ["echo 'Instance ${self.public_dns} is up!'"]
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -T 300 -i '${self.public_ip},' --extra-vars 'public_ip=${self.public_ip} hostname=${split(".", self.private_dns)[0]}' --private-key ~/.ssh/k8s-lab.pem ../ansible/master-playbook.yml"
  }
}

# Setting up worker nodes
resource "aws_instance" "kube_worker" {
  depends_on = [aws_instance.kube_master]
  count = 2

  ami           = "ami-02e2a5679226e293c" # ID of default Debian 10 ami (64-bit|x86)
  instance_type = "t2.micro" # To keep it free tier eligible we will be using t2.micro
    Name = "kube-worker"
  }
  key_name = "k8s-lab"

  provisioner "remote-exec" {
    connection {
      host = self.public_ip
      user = "admin"
      private_key = file("~/.ssh/k8s-lab.pem")
    }

    inline = ["echo 'Instance ${self.public_dns} is up!'"]
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -T 300 -i '${self.public_ip},' --private-key ~/.ssh/k8s-lab.pem ../ansible/node-playbook.yml"
  }
}