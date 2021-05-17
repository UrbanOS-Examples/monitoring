provider "helm" {

}

# Data source needs to get values:
#  - subnets
#  - albToClusterSG
#  - certificateARN
#  - dns_zone

# Variables:
#  - slack_url

resource "helm_release" "prometheus" {
    name   = "prometheus"
    chart  = "."
    values = [
        "grafana.yaml",
        "run-config.yaml",
        "alerts.yaml",
        "rules.yaml"
        "endpoints/${environment}.yaml"
        "alertManager/${environment}.yaml"
    ]

    set {
        name  = "global.ingress.annotations.\"alb\\.ingress\\.kubernetes\\.io\\/subnets\""
        value = subnets
    }
    set {
        name  = "global.ingress.annotations.\"alb\\.ingress\\.kubernetes\\.io\\/security\\-groups\""
        value = albToClusterSG
    }
    set {
        name  = "global.ingress.annotations.\"alb\\.ingress\\.kubernetes\\.io\\/certificate-arn\""
        value = certificateARN
    }
    set {
        name  = "grafana.ingress.hosts[0]"
        value = "grafana\\.${dns_zone}/*"
    }
    set {
        name  = "alertmanager.ingress.hosts[0]"
        value = "alertmanager\\.${dns_zone}/*"
    }
    set {
        name  = "server.ingress.hosts[0]"
        value = "prometheus\\.${dns_zone}/*"
    }
    set {
        name  = "pushgateway.ingress.hosts[0]"
        value = "pushgateway\\.${dns_zone}/*"
    }
    set {
        name  = "alertmanagerFiles.\"alertmanager\\.yml\".global.slack_api_url"
        value = var.slack_url
    }
}