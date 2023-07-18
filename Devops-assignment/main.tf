provider "aws" {
    region = "us-east-1"
  
}


resource "aws_s3_bucket" "bucket" {
  count         = 5
  bucket        = "peace-prefix-${count.index + 1}"
  acl           = "private"
}


resource "aws_iam_instance_profile" "instanceprofile" {
  name = "ec2-iam-instanceprofile"  
  role = aws_iam_role.ec2role.name  
}

resource "aws_iam_role" "ec2role" {
  name = "ec2-iam-role" 
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policyattach" {
  role       = aws_iam_role.ec2role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-0261755bbcb8c4a84"  # using Ubuntu 22 LTS
  instance_type = "t2.micro"     
  availability_zone = "us-east-1a"
  key_name = "Terrform-project"

    iam_instance_profile = aws_iam_instance_profile.instanceprofile.name
 
    tags = {
        Name="Devops assignment"
    }
    user_data = file("userdata.sh")
}


