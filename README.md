# Monitoring

The goal is to define a monitoring stack that can be provisioned automatically using Helm. This will serve as our initial vertical slice to define our DevOps stack. For our initial vertical slice we wanted to use something that does not have direct operational impact and hopefully is straightforward to setup.

The monitoring stack consists of:

Grafana - for Dashboards, Alerts and Notifications
Prometheus - for capturing metrics
Logging - we still need to decide how to handle logs.
Alert Manager - Used to manage alerts in Kubernetes
