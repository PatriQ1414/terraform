#Create Instance Role
resource "aws_iam_role" "instance_role" {
  name               = "my_instance_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "my_instance_role"
  }
}

#IAM Policy allow access to SSM parameneter store
resource "aws_iam_policy" "my_parameter_store" {
  name        = "my_parameter_store"
  description = "Allow access to ssm parameter store"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:CreateLogStream",
          "ec2:DescribeTags",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = {
    Name = "my_parameter_store"
  }
}

#Create Instance Profile
resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = aws_iam_role.instance_role.id
}

#Attach Policies to Instance Role
resource "aws_iam_policy_attachment" "attach_1" {
  name       = "SSMManagedInstanceCore"
  roles      = [aws_iam_role.instance_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "attach_2" {
  name       = "EC2RoleforSSM"
  roles      = [aws_iam_role.instance_role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_policy_attachment" "attach_3" {
  name       = "CloudWatchAgentServer"
  roles      = [aws_iam_role.instance_role.id]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy_attachment" "attach_4" {
  name       = "ssm-parameter-store-access"
  roles      = [aws_iam_role.instance_role.id]
  policy_arn = aws_iam_policy.ssm_parameter_policy.arn
}

#Local variables SSM Parameter Store
locals {

  userdata = templatefile("user_data.ps1", {

    ssm_cloudwatch_config = aws_ssm_parameter.my_parameter.name

  })

}

locals {

  ssm_cloudwatch_config = aws_ssm_parameter.my_parameter.name

}

#SSM Parameter
resource "aws_ssm_parameter" "my_parameter" {
  description = "Cloudwatch agent config to configure custom log"
  name        = "/cw/agent"
  type        = "String"
  value       = file("config.json")
}



#Windows EC2
resource "aws_instance" "windows-ec2" {
  ami                         = var.my_ami
  instance_type               = var.my_instance_type
  iam_instance_profile        = aws_iam_instance_profile.ssm-management-RDS.id
  security_groups             = [aws_security_group.my_security_group.id]
  subnet_id                   = aws_subnet.my_subnet.id
  user_data                   = local.userdata

  }
