
provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "yelp-analysis" {
  ami                    = "ami-0edf3b95e26a682df"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name = "ssh-access"
  tags = {
    Name = "yelp-analysis"
  }
}

resource "aws_security_group" "instance" {
  name = "yelp-analysis-instance"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

