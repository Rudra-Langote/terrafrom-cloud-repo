terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_costom_vpc"
  }
}

resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "my_costom_igw"
    }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/20"
  availability_zone = "us-east-1a"
  tags = {
    Name = "my_costom_public_subnet"
  }
  
}

resource "aws_subnet" "private_subnet-1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "us-east-1b"
    tags = {
        Name = "my_costom_private_subnet-1"
    }
}

resource "aws_subnet" "private_subnet-2" {
    vpc_id            = aws_vpc.my_vpc.id
    cidr_block        = "10.0.32.0/20"
    availability_zone = "us-east-1c"
    tags = {
      Name = "my_costom_private_subnet-2" 
    }
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_costom_public_route_table"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id 
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}  

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }    
}

resource "aws_instance" "my_web_server" {
  ami           = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.web_sg.id]
  tags = {
    Name = "my_web_server"
  }
  
}

resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Security group for application server"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/20"]
    }
}


resource "aws_instance" "my_private_server" {
  ami           = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet-1.id
  security_groups = [aws_security_group.app_sg.id]
  tags = {
    Name = "my_private_server"
  }
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet-1.id, aws_subnet.private_subnet-2.id]
  tags = {
    Name = "my_costom_db_subnet_group"
  }
  
}

resource "aws_db_instance" "my_db_instance" {
  identifier              = "my-db-instance"
  engine                  = "mysql"
  engine_version = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp2"
  username                = "root"
  password                = "password123"

  db_subnet_group_name    = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.app_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false   

  tags = {
    Name = "my_db_instance"
  }
  
}


