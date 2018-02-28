# Grafana InSpec Profile

run the tests locally with

 ```inspec exec -t docker://<container_name> docker```

Things we need to figure out:
* Do we need to worry about HA or punt at this point? - next story?
* Handling secrets management for RDS - next story
* Configure Grafana to AWS for credentials check. Is this even possible? Use OAuth?
* Configure PostgreSQL or MySQL - do we need to run some init script or it happens automatically?
* Use Redis for session. Or are we good with using memory or file for now?
* Figure out how to provision CloudWatch datasource and set variables from ENV
* Figure out how to provision Dashboards and how to pass variables
* Setup certificates if using HTTPS

* To what degree are we testing provisioning? E.g. is it sufficient we are trying to config
  CloudWatch as a datasource or we actually test successful connection? Second is trickier.
