
data "aws_ami" "amzn2" {
    owners = ["amazon"]
    name_regex = "^amzn2-ami-hvm-2.0.20200520.1-x86_64-gp2"
}

resource "aws_vpc" "demo" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true

    tags = {
        Name = "demo"
    }
}

resource "aws_internet_gateway" "demo_gw" {
    vpc_id = aws_vpc.demo.id
}

resource "aws_route_table" "demo_rtb" {
    vpc_id = aws_vpc.demo.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.demo_gw.id
    }

    tags = {
        Name = "demo"
    }
}

resource "aws_main_route_table_association" "demo_assoc" {
    vpc_id = aws_vpc.demo.id
    route_table_id = aws_route_table.demo_rtb.id
}

resource "aws_subnet" "demo_subnet" {
    vpc_id = aws_vpc.demo.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true

    depends_on = [aws_internet_gateway.demo_gw]

    tags = {
        Name = "demo"
    }
}

resource "aws_security_group" "allow_http" {
    name = "allow_http"
    description = "Allow HTTP inbound traffic"
    vpc_id = aws_vpc.demo.id

    ingress {
        description = "HTTP from world"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow_http"
    }
}

resource "aws_security_group" "allow_ssh" {
    name = "allow_ssh"
    description = "Allow SSH inbound traffic"
    vpc_id = aws_vpc.demo.id

    ingress {
        description = "SSH from world"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow_ssh"
    }
}

resource "aws_ebs_encryption_by_default" "demo" {
    enabled = true
}

resource "aws_instance" "demo_instance" {
    ami = data.aws_ami.amzn2.id
    instance_type = "t2.micro"
    key_name = "aws-personal-jb"

    private_ip = "10.0.1.10"
    subnet_id = aws_subnet.demo_subnet.id
    vpc_security_group_ids = [aws_security_group.allow_http.id,aws_security_group.allow_ssh.id]

    root_block_device {
      volume_type = "gp2"
      volume_size = 20
    }

    ebs_block_device {
      device_name = "/dev/sdg"
      volume_type = "gp2"
      volume_size = 1
    }
}

resource "aws_eip" "demo_eip" {
    vpc = true
    instance = aws_instance.demo_instance.id
    associate_with_private_ip = "10.0.1.10"
    depends_on = [aws_internet_gateway.demo_gw]
}

