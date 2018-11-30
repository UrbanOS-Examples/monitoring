provider "aws" {
  version = "1.39"
  region  = "${var.alm_region}"

  assume_role {
    role_arn = "${var.alm_role_arn}"
  }
}

data "terraform_remote_state" "env_remote_state" {
  backend   = "s3"
  workspace = "${terraform.workspace}"

  config {
    bucket   = "${var.alm_state_bucket_name}"
    key      = "operating-system"
    region   = "us-east-2"
    role_arn = "${var.alm_role_arn}"
  }
}

data "terraform_remote_state" "alm_remote_state" {
  backend   = "s3"
  workspace = "${var.alm_workspace}"

  config {
    bucket   = "${var.alm_state_bucket_name}"
    key      = "alm"
    region   = "us-east-2"
    role_arn = "${var.alm_role_arn}"
  }
}

data "terraform_remote_state" "alm_durable_remote_state" {
  backend   = "s3"
  workspace = "${var.alm_workspace}"

  config {
    bucket   = "${var.alm_state_bucket_name}"
    key      = "alm-durable"
    region   = "us-east-2"
    role_arn = "${var.alm_role_arn}"
  }
}

resource "local_file" "kubeconfig" {
  filename = "${path.module}/outputs/kubeconfig"
  content = "${data.terraform_remote_state.env_remote_state.eks_cluster_kubeconfig}"
}

data "aws_secretsmanager_secret_version" "bind_user_password" {
  secret_id = "${data.terraform_remote_state.alm_remote_state.bind_user_password_secret_id}"
}

locals {
  ldapPath = "cn=accounts,dc=${replace(data.terraform_remote_state.alm_durable_remote_state.hosted_zone_name, ".", ",dc=")}"
  ldapUri = "ldap://iam-master.${data.terraform_remote_state.alm_remote_state.public_hosted_zone_name}:389/${local.ldapPath}"
  dns_zone = "${terraform.workspace}.internal.smartcolumbusos.com"
  datalake_url = "http://datalake.${local.dns_zone}:6188"
}

resource "local_file" "helm_vars" {
  filename = "${path.module}/outputs/${terraform.workspace}.yaml"
  content = <<-EOF
    global:
      ingress:
        annotations:
          alb.ingress.kubernetes.io/scheme: "${var.is_internal ? "internal" : "internet-facing"}"
          alb.ingress.kubernetes.io/subnets: "${join(",", data.terraform_remote_state.env_remote_state.public_subnets)}"
          alb.ingress.kubernetes.io/security-groups: "${data.terraform_remote_state.env_remote_state.allow_all_security_group}"
          alb.ingress.kubernetes.io/certificate-arn: "${data.terraform_remote_state.env_remote_state.tls_certificate_arn}"
        domain: "kylo.${data.terraform_remote_state.env_remote_state.dns_zone_name}"
      entityLevelSecurity: true
    ldap:
      config: |-
        verbose_logging = true
        [[servers]]
        host = "iam-master.alm.internal.smartcolumbusos.com"
        port = 636
        use_ssl = true
        start_tls = false
        ssl_skip_verify = true
        bind_dn = "uid=binduser,cn=users,cn=accounts,dc=internal,dc=smartcolumbusos,dc=com"
        bind_password = "${data.aws_secretsmanager_secret_version.bind_user_password.secret_string}"
        search_filter = "(uid=%s)"
        search_base_dns = ["cn=users,cn=accounts,dc=internal,dc=smartcolumbusos,dc=com"]
        [[servers.group_mappings]]
        group_dn = "*"
        org_role = "Admin"
        grafana_admin = true
    grafana:
      ingress:
        hosts:
          - "grafana.data.${data.terraform_remote_state.env_remote_state.dns_zone_name}"
      datasources:
        datasources.yaml.datasources:
        - url: ${local.datalake_url}
    alertmanager:
      ingress:
        hosts:
          - "alertmanager.${data.terraform_remote_state.env_remote_state.dns_zone_name}"
    server:
      ingress:
        hosts:
          - "prometheus.${local.dns_zone}"
    alertmanagerFiles:
      alertmanager.yml:
        global:
          slack_api_url: "slack.com"
    EOF
}



resource "null_resource" "helm_deploy" {
  provisioner "local-exec" {
    command = <<-EOF
      set -x
      export KUBECONFIG=${local_file.kubeconfig.filename}

      helm init --client-only
      helm dependency update
      helm upgrade --install prometheus . \
          --namespace=prometheus \
          --values ${local_file.helm_vars.filename} \
          --values run-config.yaml \
          --values alerts.yaml \
          --values rules.yaml \
          --values endpoints/${terraform.workspace}.yaml \
          --values alertManager/${terraform.workspace}.yaml
      EOF
  }

  triggers {
    # Triggers a list of values that, when changed, will cause the resource to be recreated
    # ${uuid()} will always be different thus always executing above local-exec
    hack_that_always_forces_null_resources_to_execute = "${uuid()}"
  }
}

variable "alm_role_arn" {
  description = "The ARN for the assume role for ALM access"
  default     = "arn:aws:iam::199837183662:role/jenkins_role"
}

variable "alm_workspace" {
  description = "The workspace to pull ALM outputs from"
  default     = "alm"
}

variable "alm_state_bucket_name" {
  description = "The name of the S3 state bucket for ALM"
  default     = "scos-alm-terraform-state"
}

variable "is_internal" {
  description = "Should the ALBs be internal facing"
  default     = false
}

variable "alm_region" {
  description = "Region of ALM resources"
  default     = "us-east-2"
}
