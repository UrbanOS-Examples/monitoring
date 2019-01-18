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

For a "fully" configured version, the following config files are available.

```bash
helm upgrade --install prometheus . \
  --namespace monitoring \
  --values rules.yaml \
  --values alerts.yaml \
  --values grafana.yaml
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
kubectl -n prometheus exec -it prometheus-grafana-0 -c grafana -- grafana-cli admin reset-admin-password --homepath /usr/share/grafana {password}
```

### Dashboards

***Warning***: Do not clone public dashboards without first removing their gnet ID in the JSON and their import entry in the chart. If this is not done, the dashboard will redownload every three seconds or so and fill up the volume with backed-up old versions.

### Adding New Datasources

To add a new provisioned datasource to grafana, add it to the datasources configmap.
[templates/grafana-configmap-datasource.yaml](templates/grafana-configmap-datasource.yaml)

### Delete Persistent Volume script

This script will wipe out the persistent volumes and stateful sets in monitoring, in case such a thing is necessary (eg the drives are full). It is commented out for safety. Please ensure that your kubeconfig is pointed to your desired environment before uncommenting and running the script. Details on how to do that are found in the team-configs repo. 

### A note on the Cloudwatch Datasource

Currently, the cloudwatch datasource for grafana is set to use a credentials file as authentication, but we don't give it a credential file. Instead, the permissions set on the eks worker allow grafana to talk to cloudwatch.
