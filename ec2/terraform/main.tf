
provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "yelp-analysis" {
  ami                    = "ami-0edf3b95e26a682df"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name = "ssh-access"
  user_data = <<-EOF
              #!/bin/bash
              sudo file -s /dev/xvdf
              sudo mkfs -t ext4 /dev/xvdf
              sudo mkdir /data
              sudo mount /dev/xvdf /data/
              EOF
  root_block_device {
    delete_on_termination = true
 }
  tags = {
    Name = "yelp-analysis"
  }
}

resource "aws_ebs_volume" "ebs-volume" {
  availability_zone = "us-west-2a"
  size              = 32
}

resource "aws_volume_attachment" "ebs_att" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.ebs-volume.id
  instance_id  = aws_instance.yelp-analysis.id
  force_detach = true
}

resource "aws_security_group" "instance" {
  name = "yelp-analysis-instance"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value       = aws_instance.yelp-analysis.public_ip
  description = "The public IP of the web server"
}
