library(
    identifier: 'pipeline-lib@4.3.6',
    retriever: modernSCM([$class: 'GitSCMSource',
                          remote: 'https://github.com/SmartColumbusOS/pipeline-lib',
                          credentialsId: 'jenkins-github-user'])
)

properties([
    pipelineTriggers([scos.dailyBuildTrigger()]),
])

def doStageIf = scos.&doStageIf
def doStageIfRelease = doStageIf.curry(scos.changeset.isRelease)
def doStageUnlessRelease = doStageIf.curry(!scos.changeset.isRelease && !scos.changeset.isHotfix)
def doStageIfPromoted = doStageIf.curry(scos.changeset.isMaster)
def doStageIfHotfix = doStageIf.curry(scos.changeset.isHotfix)

node('infrastructure') {
    ansiColor('xterm') {

        scos.doCheckoutStage()

        doStageUnlessRelease('Deploy to Dev') {
            deployMonitoringTo('dev')
        }

         doStageIfPromoted('Deploy to Staging') {
            def promotionTag = scos.releaseCandidateNumber()

            deployMonitoringTo('staging')

            scos.applyAndPushGitHubTag(promotionTag)
        }

        doStageIfRelease('Deploy to Production') {
            def releaseTag = env.BRANCH_NAME
            def promotionTag = 'prod'

            deployMonitoringTo('prod')

            scos.applyAndPushGitHubTag(promotionTag)
        }
    }
}

def deployMonitoringTo(environment) {
    scos.withEksCredentials(environment) {
        def terraformOutputs = scos.terraformOutput(environment)
        def subnets = terraformOutputs.public_subnets.value.join(/\\,/)
        def albToClusterSG = terraformOutputs.allow_all_security_group.value
        def dns_zone = environment + '.internal.smartcolumbusos.com'
        def certificateARN = terraformOutputs.tls_certificate_arn.value

        withCredentials([string(credentialsId: "slack-webhook-${environment}", variable: 'SLACK_URL')]) {
            sh("""#!/bin/bash

                helm init --client-only
                helm dependency update
                helm upgrade --install prometheus . \
                    --namespace=prometheus \
                    --set global.ingress.annotations."alb\\.ingress\\.kubernetes\\.io\\/subnets"="${subnets}" \
                    --set global.ingress.annotations."alb\\.ingress\\.kubernetes\\.io\\/security\\-groups"="${albToClusterSG}" \
                    --set global.ingress.annotations."alb\\.ingress\\.kubernetes\\.io\\/certificate-arn"="${certificateARN}" \
                    --set grafana.ingress.hosts[0]="grafana\\.${dns_zone}/*" \
                    --set alertmanager.ingress.hosts[0]="alertmanager\\.${dns_zone}" \
                    --set server.ingress.hosts[0]="prometheus\\.${dns_zone}" \
                    --set alertmanagerFiles."alertmanager\\.yml".global.slack_api_url=$SLACK_URL \
                    --values grafana.yaml \
                    --values run-config.yaml \
                    --values alerts.yaml \
                    --values rules.yaml \
                    --values endpoints/${environment}.yaml \
                    --values alertManager/${environment}.yaml \
                    --set grafana.datasource.ambari.host="datalake.${dns_zone}"
            """.trim())

            // TODO: Find a better place to keep the hadoop dashboards now that we've decoupled them
            sh "kubectl --namespace prometheus apply -f dashboards/scos-hdp-cluster.yaml"
            sed -i "s/{{env_name}}/${environment}/" dashboards/scos-aws-daily-cost.yaml
            sh "kubectl --namespace prometheus apply -f dashboards/scos-aws-daily-cost.yaml "
        }
    }
}
