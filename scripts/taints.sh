if [[ -z $1 ]]; then
    echo "must supply command. Use one of [show, fix]"
    exit 1
else
    COMMAND=$1
fi

if [[ -z $2 ]]; then
    TAINT_TYPE=CriticalAddonsOnly
else
    TAINT_TYPE=$1
fi
kubectl get ValidatingWebhookConfiguration aks-node-validating-webhook -o yaml | sed -e 's/\(objectSelector: \){}/\1{"matchLabels": {"disable":"true"}}/g' | kubectl apply -f -

case $COMMAND in
"show")
    # todo, loop and remove all
    kubectl get nodes -o json | jq '.items | flatten | map({taints: .spec.taints, node: .metadata.name}) '
    ;;
"remove")
    kubectl taint nodes --all $TAINT_TYPE-
    kubectl get nodes -o json | jq '.items | flatten | map({taints: .spec.taints, node: .metadata.name}) '
    ;;
\?)
    echo "Use one of [show, fix]"
    ;;
*)
    echo "Invalid command. Use one of [show, fix]" >&2
    exit 1
    ;;
esac
