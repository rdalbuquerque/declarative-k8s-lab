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
  instance_type = "t2.micro" # minimum requirement for kubernetes is 2 cpus and 2 gb of ram wich would be a chargeable EC2, so we will try the micro anyways

  tags = {
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
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -T 300 -i '${self.public_ip},' --extra-vars 'private_ip=${self.private_ip} hostname=${split(".", self.private_dns)[0]}' --private-key ~/.ssh/k8s-lab.pem ../ansible/master-playbook.yml"
  }
}

#resource "null_resource" "master_playbook" {
#
#  provisioner "remote-exec" {
#    connection {
#      host = aws_instance.kube_master.public_ip
#      user = "admin"
#      private_key = file("~/.ssh/rda.pem")
#    }
#
#    inline = ["echo 'Instance ${aws_instance.kube_master.public_dns} is up!'"]
#  }
#
#  provisioner "local-exec" {
#    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -T 300 -i '${aws_instance.kube_master.public_ip},' --extra-vars 'private_ip=${aws_instance.kube_master.private_ip} hostname=${split(".", aws_instance.kube_master.private_dns)[0]}' --private-key ~/.ssh/rda.pem ../KubeSetup/master-playbook.yml"
#  }
#
#}

# Setting up worker nodes
resource "aws_instance" "kube_worker" {
  depends_on = [aws_instance.kube_master]
  count = 2

  ami           = "ami-02e2a5679226e293c" # ID of default Debian 10 ami (64-bit|x86)
  instance_type = "t2.micro" # minimum requirement for kubernetes is 2 cpus and 2 gb of ram wich would be a chargeable EC2, so we will try the micro anyways

  tags = {
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

