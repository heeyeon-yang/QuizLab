data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_launch_template" "quizlab_lt" {
  name_prefix   = "quizlab-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "QuizLab server $(hostname -f)" > /usr/share/nginx/html/index.html
  USERDATA
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "quizlab-app-server"
      Project = "QuizLab"
    }
  }
}
