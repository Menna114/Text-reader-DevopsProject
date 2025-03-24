module "networking" {
  source = "./networking"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
  cidr_public_subnet = var.cidr_public_subnet
  cidr_private_subnet = var.cidr_private_subnet
  eu_availability_zone = var.eu_availability_zone
}

module "security_group" {
  source              = "./security-groups"
  ec2_sg_name         = "SG for EC2 to enable SSH(22), HTTPS(443), and HTTP(80)"
  vpc_id              = module.networking.dev_proj_1_vpc_id
  ec2_jenkins_sg_name = "Allow port 8080 for Jenkins"
}

module "ec2-jenkins" {
  source                    = "./ec2-instance"
  ami_id                    = var.ec2_ami_id
  instance_type             = "t2.medium"
  tag_name                  = "Jenkins:EC2 instance"
  public_key                = var.public_key
  subnet_id                 = tolist(module.networking.dev_proj_1_public_subnets)[0]
  sg_for_jenkins            = [module.security_group.sg_ec2_sg_ssh_http_id,module.security_group.sg_ec2_jenkins_port_8080]
  enable_public_ip_address  = true
  user_data_install_jenkins = templatefile("./jenkins-runner-script/jenkins-installer.sh", {})
}
module "lb-target-group" {
  source                   = "./lb-target-groups"
  lb_target_group_name     = "jenkins-lb-target-group"
  lb_target_group_port     = 8080
  lb_target_group_protocol = "HTTP"
  vpc_id                   = module.networking.dev_proj_1_vpc_id
  ec2_instance_id          = module.ec2-jenkins.jenkins_ec2_instance_ip
}