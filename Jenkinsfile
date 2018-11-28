library(
    identifier: 'pipeline-lib@4.3.0',
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
        def almOutputs = scos.terraformOutput('alm')
        def subnets = terraformOutputs.public_subnets.value.join(/\\,/)
        def albToClusterSG = terraformOutputs.allow_all_security_group.value
        def dns_zone = environment + '.internal.smartcolumbusos.com'
        def datalake_url = "http://datalake.${dns_zone}:6188"
        def bind_password = almOutputs.bind_user_password_secret_id

        withCredentials([string(credentialsId: "slack-webhook-${environment}", variable: 'SLACK_URL')]) {
            sh("""#!/bin/bash

                helm init --client-only
                helm dependency update
                helm upgrade --install prometheus . \
                    --namespace=prometheus \
                    --set global.ingress.annotations."alb\\.ingress\\.kubernetes\\.io\\/subnets"="${subnets}" \
                    --set global.ingress.annotations."alb\\.ingress\\.kubernetes\\.io\\/security\\-groups"="${albToClusterSG}" \
                    --set grafana.ingress.hosts[0]="grafana\\.${dns_zone}" \
                    --set alertmanager.ingress.hosts[0]="alertmanager\\.${dns_zone}" \
                    --set server.ingress.hosts[0]="prometheus\\.${dns_zone}" \
                    --set alertmanagerFiles."alertmanager\\.yml".global.slack_api_url=$SLACK_URL \
                    --set grafana.datasources."datasources\\.yaml".datasources[1].url="${datalake_url}" \
                    --set ldap.config.bind_password="""
                            verbose_logging = true
                            [[servers]]
                            host = "iam-master.alm.internal.smartcolumbusos.com"
                            port = 636
                            use_ssl = true
                            start_tls = false
                            ssl_skip_verify = true
                            bind_dn = "uid=binduser,cn=users,cn=accounts,dc=internal,dc=smartcolumbusos,dc=com"
                            ldap_bind_password="${bind_password}"
                            """
                    --values run-config.yaml \
                    --values alerts.yaml \
                    --values rules.yaml \
                    --values endpoints/${environment}.yaml \
                    --values alertManager/${environment}.yaml
            """.trim())
        }
    }
}
