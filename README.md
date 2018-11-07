# Monitoring

The goal is to define a monitoring stack that can be provisioned automatically using Helm. This will serve as our initial vertical slice to define our DevOps stack. For our initial vertical slice we wanted to use something that does not have direct operational impact and hopefully is straightforward to setup.

The monitoring stack consists of:

Grafana - for Dashboards, Alerts and Notifications
Prometheus - for capturing metrics
Logging - we still need to decide how to handle logs.
Alert Manager - Used to manage alerts in Kubernetes
BlackBox Exporter - Used for monitoring endpoints from end-user perspective
    - [Helm Chart](https://github.com/helm/charts/tree/master/stable/prometheus-blackbox-exporter)
    - [Github](https://github.com/prometheus/blackbox_exporter)

## Retrieving Grafana Credentials

```bash
kubectl --namespace prometheus get secret prometheus-grafana -o jsonpath='{.data.admin-user}' \
    | base64 --decode && echo

kubectl --namespace prometheus get secret prometheus-grafana -o jsonpath='{.data.admin-password}' \
    | base64 --decode && echo
```

## Directory Structure

- [endpoints](endpoints/): List of "external" endpoints to monitor (per environment)
- [alerts.yaml](alerts.yaml): Defines the Prometheus Alerts
- [alertManager](alertManager/): Alert notification configuration and routing (per environment)
- [rules.yaml](rules.yaml): Prometheus rules (pre-aggregated queries)
