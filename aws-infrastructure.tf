
# Creating Vpc
resource "aws_vpc" "main_vpc" {
    cidr_block = "10.1.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
}

# Creating Subnet
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.1.1.0/24" // Make sure that subnets don't over lap with another subnet
    map_public_ip_on_launch = true // Give instance in this subnet a public ip e.g "Public Subnet"
}

# Creating private subnet
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.1.2.0/24" // Here you can see that every subnet have it's own cidr block
    map_public_ip_on_launch = false // By doing this i don't give any instance in subnet a public ip e.g "Private Subnet"
}

# Creating Internet Gateway For Public Subnet
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id
}

# Creating route table
resource "aws_route_table" "rtb" {
    vpc_id = aws_vpc.main_vpc.id
}

# Creating routing to internet gateway
resource "aws_route" "igw_route" {
    route_table_id = aws_route_table.rtb.id
    destination_cidr_block = "0.0.0.0/0" // This means that it's routes to the whole internet
    gateway_id = aws_internet_gateway.igw.id
}

# Associate public subnet to the route table
resource "aws_route_table_association" "a" {
    route_table_id = aws_route_table.rtb.id
    subnet_id = aws_subnet.public_subnet.id
}

# Creating Security Group for bastion server
resource "aws_security_group" "bastion_sg" {
    vpc_id = aws_vpc.main_vpc.id
    description = " Security Group For Bastion Host"

    ingress {
        description = "rule for allowing ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] // This is means the whole internet
    }

    egress {
        from_port = 0 // This means from any port
        to_port = 0 // This means to any port
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"] // This is means the whole internet
    }
}
resource "aws_security_group" "web_server_sg" {
    vpc_id = aws_vpc.main_vpc.id
    description = "Security Group for web server"

    ingress {
        description = "rule for allowing ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["197.48.173.81/32"] // My ip (best practice for testing) don't do "0.0.0.0/0"
    }

    ingress {
        description = "rule for allowing http"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] // This for the whole internet to access the website
    }

    egress {
        from_port = 0 // This means from any port
        to_port = 0 // This means to any port
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"] // This is means the whole internet
    }
}

# Creating Security Group For The Private Subnet
resource "aws_security_group" "private_sg" {
    vpc_id = aws_vpc.main_vpc.id
    description = "For allowing any vm in the vpc to connect to the private vms"

    ingress {
        description = "allowing ssh into the private vm"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.bastion_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = [aws_security_group.bastion_sg.id]
    }
}

# Making Public Virtual Machine (Bastion Host)
resource "aws_instance" "bastion_host" {
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.bastion_sg.id]
    instance_type = "t3.micro"
    key_name = "main-pc" // Key pair to ssh into the vm
    ami = "ami-01d565a5f2da42e6f" // Red Hat v9 Image
}

# Creating Web Server Instance
resource "aws_instance" "web_server" {
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.web_server_sg.id]
    instance_type = "t3.micro"
    key_name = "main-pc" // Key pair to ssh into the vm
    ami = "ami-01d565a5f2da42e6f" // Red Hat v9 Image
    user_data = <<-EOF
                #!/bin/bash
                yum update -y && yum upgrade -y && yum install -y git && yum install -y httpd
                systemctl start httpd
                systemctl enable httpd
                cd /home/ec2-user
                git clone https://github.com/MoamenZyan/Zyan-Website.git
                cp -r Zyan-Website/* /var/www/html
                rm -rf Zyan-Website
                echo "End Of User Data"
                EOF
}

# Making Private Virtual Machine
resource "aws_instance" "private_vm" {
    vpc_security_group_ids = [aws_security_group.private_sg.id]
    ami = "ami-0014ce3e52359afbd" // Ubuntu Image
    instance_type = "t3.micro"
    key_name = "main-pc" // It should different key than the public one but this for test perposes
    subnet_id = aws_subnet.private_subnet.id
}


# Getting public ip of bastion host server
output "public_ip_of_bastion_host" {
    value = aws_instance.bastion_host.public_ip
}

# Getting public ip of web server
output "public_ip_of_web_server" {
    value = aws_instance.web_server.public_ip
}

# Getting private ip of private vm
output "private_ip_of_private_vm" {
    value = aws_instance.private_vm.private_ip
}
