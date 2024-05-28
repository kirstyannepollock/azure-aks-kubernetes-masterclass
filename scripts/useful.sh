 kubectl get nodes -o json | jq .items[].spec.taints
 kubectl get ValidatingWebhookConfiguration aks-node-validating-webhook -o yaml | sed -e 's/\(objectSelector: \){}/\1{"matchLabels": {"disable":"true"}}/g' | kubectl apply -f -
 kubectl taint nodes --all CriticalAddonsOnly-