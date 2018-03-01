# Monitoring

The goal is to define a monitoring stack that can be provisioned automatically using Terraform. This will serve as our initial vertical slice to define our DevOps stack.
For our initial vertical slice we wanted to use something that does not have direct operational impact and hopefully is straightforward to setup.

The monitoring stack consists of:
* Grafana - for Dashboards, Alerts and Notifications
* Prometheus  - for capturing metrics
* Logging - we still need to decide how to handle logs.

Initially Grafana will be configured to use CloudWatch as a DataSource but we are going to add Prometheus as a datasource at a later point.

All the infrastructure components will support a local mode via Docker and Docker Compose and a local mode using Terraform and a cloud provider such as AWS.
We support the local mode so that is easy to experiment and to get fast feedback. Each of the components need to be automatically tested both locally and in the cloud.

## Grafana

For now we are starting with an empty instance of Grafana. Next stories need
to focus on automatically provisioning Grafana with Dashboards, Data Source and handling Authentication. Also we will need to figure out how to implement High Availability for Grafana.

To start and test Grafana locally run the following commands:


```
docker run -d --name=grafana -p 3000:3000 grafana/grafana
inspec exec -t docker://grafana grafana/test/local/docker
```

Note: This assumes both Docker and InSpec are installed locally
