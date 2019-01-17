kubectl get pvc -n prometheus
kubectl delete pvc prometheus-grafana -n prometheus
kubectl delete pvc storage-prometheus-grafana-0  -n prometheus
kubectl get pv -n prometheus | grep grafana
var=`kubectl get pv -n prometheus -o=custom-columns=NAME:.metadata.name,Namespace:.spec.claimRef.name | grep prometheus-grafana | grep -o '^[^ ]*' | sed '/^$/d'`
while read -r line; do
    kubectl delete pv $line
done <<< "$var"
kubectl delete pod/prometheus-grafana-0 -n prometheus