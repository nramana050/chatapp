provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "frontend" {
  ami           = "ami-0c55b159cbfafe1f0" 
  instance_type = "t2.micro"
  key_name      = "key"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              # Install Node.js and necessary packages for frontend
              curl -sL https://rpm.nodesource.com/setup_14.x | bash -
              yum install -y nodejs
              git clone https://github.com/koolkishan/chat-app-react-nodejs.git /var/www/html
              cd /var/www/html/frontend
              npm install
              npm run build
              cp -r build/* /var/www/html
              EOF

  tags = {
    Name = "Frontend-Server"
  }
}

resource "aws_instance" "backend" {
  ami           = "ami-0c55b159cbfafe1f0" 
  instance_type = "t2.micro"
  key_name      = "key"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git
              # Install Node.js and necessary packages for backend
              curl -sL https://rpm.nodesource.com/setup_14.x | bash -
              yum install -y nodejs
              git clone https://github.com/koolkishan/chat-app-react-nodejs.git /home/ec2-user/chat-app
              cd /home/ec2-user/chat-app/backend
              npm install
              node app.js &
              EOF

  tags = {
    Name = "Backend-Server"
  }
}

resource "aws_db_instance" "mongo" {
  identifier             = "chat-app-mongo"
  engine                 = "mongo"
  instance_class         = "db.t2.micro"
  allocated_storage      =  20
  name                   = "chatdb"
  username               = "admin"
  password               = "password"
  skip_final_snapshot    = true

  tags = {
    Name = "MongoDB"
  }
}

resource "aws_alb" "alb" {
  name               = "chat-app-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_route53_record" "frontend" {
  zone_id = "var.route53_zone_id"
  name    = "frontend"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.frontend.public_ip]
}

resource "aws_route53_record" "backend" {
  zone_id = "var.route53_zone_id"
  name    = "backend"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.backend.public_ip]
}

output "frontend_url" {
  value = aws_instance.frontend.public_ip
}

output "backend_url" {
  value = aws_instance.backend.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.mongo.address
}
