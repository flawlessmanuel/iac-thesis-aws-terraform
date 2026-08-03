# compute.tf

# 1. GET THE LATEST AMAZON LINUX AMI (The Operating System)
# Instead of hardcoding an ID, we ask AWS for the latest one.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"] # Amazon Linux 2023
  }
}

# 2. LAUNCH TEMPLATE (The Blueprint)
# This defines WHAT server to create (OS, Size, Setup Script)
resource "aws_launch_template" "web_server" {
  name_prefix   = "${var.project_name}-template-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name = "thesis-debug-key"

  # Network settings
  network_interfaces {
    associate_public_ip_address = true # Needed to download Apache without NAT Gateway
    security_groups             = [aws_security_group.web_sg.id]
  }

  # THE SETUP SCRIPT (User Data)
  # This runs automatically when the server turns on.
  # NOTE: all output is redirected to /var/log/user-data.log so it can be
  # inspected later (via SSH or EC2 Instance Connect) without guessing.
  # The HTML file is written line-by-line with printf instead of a nested
  # heredoc, which avoids CRLF/indentation issues entirely.
  user_data = base64encode(replace(<<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -x

    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd

    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

    HTML_FILE=/var/www/html/index.html
    {
      printf '%s\n' '<!DOCTYPE html>'
      printf '%s\n' '<html>'
      printf '%s\n' '<head><title>Thesis Defense Demo</title>'
      printf '%s\n' '<style>'
      printf '%s\n' "body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f0f2f5; color: #333; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }"
      printf '%s\n' ".card { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 8px 16px rgba(0,0,0,0.1); max-width: 500px; text-align: center; border-top: 5px solid #FF9900; }"
      printf '%s\n' "h1 { color: #232F3E; margin-top: 0; }"
      printf '%s\n' ".badge { background-color: #e6f4ea; color: #1e8e3e; padding: 5px 10px; border-radius: 20px; font-size: 14px; font-weight: bold; display: inline-block; margin-bottom: 20px; }"
      printf '%s\n' ".metadata { background: #f8f9fa; border: 1px solid #dee2e6; padding: 15px; border-radius: 8px; text-align: left; font-family: monospace; font-size: 14px; color: #d63200; }"
      printf '%s\n' '</style></head>'
      printf '%s\n' '<body>'
      printf '%s\n' '<div class="card">'
      printf '%s\n' '<h1>Cloud Architecture Defense</h1>'
      printf '%s\n' '<div class="badge">Live Production Environment</div>'
      printf '%s\n' '<p>Welcome to the automated 3-Tier Web Architecture deployed entirely via Infrastructure as Code (Terraform).</p>'
      printf '%s\n' '<div class="metadata">'
      printf '<p><strong>Serving from Instance:</strong> %s</p>\n' "$INSTANCE_ID"
      printf '<p><strong>Availability Zone:</strong> %s</p>\n' "$AZ"
      printf '%s\n' '</div></div></body></html>'
    } > "$HTML_FILE"

    chown apache:apache "$HTML_FILE"
    systemctl restart httpd
  EOF
  , "\r\n", "\n"))
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-WebServer"
    }
  }
}

# 3. LOAD BALANCER (The Traffic Cop)
resource "aws_lb" "main_lb" {
  name               = "${var.project_name}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "${var.project_name}-ALB"
  }
}

# 4. TARGET GROUP (The List of Servers)
# The Load Balancer sends traffic to this group.
resource "aws_lb_target_group" "web_tg" {
  name     = "${var.project_name}-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# 5. LISTENER (The Ear)
# The Load Balancer listens on Port 80 and forwards to the Target Group.
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 6. AUTO SCALING GROUP (The Automation)
# This actually launches the servers based on the Launch Template.
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity    = 2  # Start with 2 servers
  max_size            = 3  # Scale up to 3 if busy
  min_size            = 1  # Never go below 1
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id] # Using public for free internet access
  target_group_arns   = [aws_lb_target_group.web_tg.arn]

  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }
}