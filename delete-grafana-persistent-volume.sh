# kubectl get pvc -n prometheus
# kubectl delete pvc prometheus-grafana -n prometheus
# kubectl delete pvc storage-prometheus-grafana-0  -n prometheus
# kubectl get pv -n prometheus | grep grafana
# kubectl get pv -n prometheus -o=custom-columns=NAME:.metadata.name,Namespace:.spec.claimRef.name | grep prometheus-grafana | grep -o '^[^ ]*' | sed '/^$/d' |awk 'system("kubectl delete pv " $1)'
# kubectl delete pod/prometheus-grafana-0 -n prometheus