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

## Directory Structure

- [endpoints](endpoints/): List of "external" endpoints to monitor (per environment)
- [alerts.yaml](alerts.yaml): Defines the Prometheus Alerts
- [alertManager](alertManager/): Alert notification configuration and routing (per environment)
- [rules.yaml](rules.yaml): Prometheus rules (pre-aggregated queries)
- [grafana.yaml](grafana.yaml): Grafana dashboard/datasource configuration and dashboards from the public grafana dashboard repository.
- [dashboards](dashboards/): Custom grafana dashboards. (These should eventually be moved to live with their own applications.)

## Minikube

This stack takes quite a bit of resources to run.
It's recommended to run with at least 6GB of memory and at least 3 cpus.

```bash
minikube start --memory 6144 --cpus 3
helm upgrade --install prometheus . --namespace monitoring
```

## Grafana

### Retrieving Credentials

```bash
kubectl --namespace prometheus get secret prometheus-grafana -o jsonpath='{.data.admin-user}' \
    | base64 --decode && echo

kubectl --namespace prometheus get secret prometheus-grafana -o jsonpath='{.data.admin-password}' \
    | base64 --decode && echo
```

[There's a bug in the chart that causes the secret to change when helm upgrade is run, but Grafana doesn't pick up the new admin password.](https://github.com/helm/charts/issues/5167)

To sync things back up, retrieve the password, then reset it via the `grafana-cli`.

```bash
kubectl -n prometheus exec -it prometheus-grafana-0 -- grafana-cli admin reset-admin-password --homepath /usr/share/grafana {password}
```

### Adding New Datasources

To add a new provisioned datasource to grafana, add it to the datasources configmap.
[templates/grafana-configmap-datasource.yaml](templates/grafana-configmap-datasource.yaml)