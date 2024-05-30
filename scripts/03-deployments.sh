source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

DEPLOYMENT_NAME=my-first-deployment
SERVICE_NAME=$DEPLOYMENT_NAME-service

if [[ $1 = "init" ]]; then
    kubectl create deployment $DEPLOYMENT_NAME --image=ghcr.io/stacksimplify/kubenginx:1.0.0
    kubectl expose deployment $DEPLOYMENT_NAME --type=LoadBalancer --port=80 --target-port=80 --name=$SERVICE_NAME
    kubectl get services
    kubectl get pods -o wide
fi

if [[ $1 = "update" ]]; then
    if [[ -z $2 ]]; then
        MAJ_VER=1
    else
        MAJ_VER=$2
    fi
    echo using image - ghcr.io/stacksimplify/kubenginx:$MAJ_VER.0.0
    # NOTE: seems here we must use deployment/$DEPLOYMENT_NAME
    kubectl set image deployment/$DEPLOYMENT_NAME kubenginx=ghcr.io/stacksimplify/kubenginx:$MAJ_VER.0.0
    INFO=$(kubectl -ojson get deployment $DEPLOYMENT_NAME)
    IMAGE=$(jq -r .spec.template.spec.containers[0].image <<<$INFO)
    echo IMAGE
    echo $IMAGE
    echo ROLLOUT
    kubectl rollout status deployment/$DEPLOYMENT_NAME
    echo EVENTS
    kubectl events --for deployment/$DEPLOYMENT_NAME
    echo REPLICASET
    kubectl get deployment $DEPLOYMENT_NAME
fi

if [[ $1 = "show" ]]; then
    kubectl get services
    kubectl get deployment $DEPLOYMENT_NAME
    echo "IMAGE"
    kubectl -ojson get deployment $DEPLOYMENT_NAME | jq -r .spec.template.spec.containers[0].image
    #kubectl describe deployment $DEPLOYMENT_NAME
    kubectl get pods -o wide
fi

if [[ $1 = "contact" ]]; then
    URL="$(getK8sServiceUrl $SERVICE_NAME)"
    echo contacting $SERVICE_NAME on $URL ...
    curl $URL
    echo
fi

if [[ $1 = "scale" ]]; then
    kubectl scale --replicas=$2 deployment/$DEPLOYMENT_NAME
    kubectl get pods -o wide
fi

if [[ $1 = "delete" ]]; then
    kubectl delete deployment $DEPLOYMENT_NAME
    kubectl delete service $SERVICE_NAME
fi

if [[ $1 = "history" ]]; then
    kubectl rollout history deployment/$DEPLOYMENT_NAME
    kubectl get replicaset
    kubectl events --for deployment/$DEPLOYMENT_NAME

fi

if [[ $1 = "rollback" ]]; then
    echo "IMAGE:before "
    kubectl -ojson get deployment $DEPLOYMENT_NAME | jq -r .spec.template.spec.containers[0].image

    if [[ -z $2 ]]; then
        kubectl rollout undo deployment/my-first-deployment
    else
        kubectl rollout undo deployment/my-first-deployment --to-revision=$2
    fi

    # DATA=$(kubectl rollout history deployment/$DEPLOYMENT_NAME -o json) # it isnt JSON!
    # #echo $DATA

    # # awk '{gsub(/} {/,"},{"); print}' <<<"{idea} {item} {intuit}" ## this works

    # #this does not
    # JSON=$(awk '{gsub(/} {/,"},{"); print}' <<<$DATA)
    # JSON="[$JSON]"
    # echo $JSON

    echo "IMAGE: after"
    kubectl -ojson get deployment $DEPLOYMENT_NAME | jq -r .spec.template.spec.containers[0].image
fi

if [[ $1 = "pause" ]]; then
    kubectl rollout pause deployment/$DEPLOYMENT_NAME
    kubectl set image deployment/$DEPLOYMENT_NAME kubenginx=ghcr.io/stacksimplify/kubenginx:4.0.0

    # Check the Rollout History of a Deployment
    kubectl rollout history deployment/$DEPLOYMENT_NAME
    #Observation: No new rollout should start, we should see same number of versions as we check earlier with last version number matches which we have noted earlier.

    kubectl get rs
    #Observation: No new replicaSet created. We should have same number of replicaSets as earlier when we took note.

    # Make one more change: set limits to our container
    kubectl set resources deployment/$DEPLOYMENT_NAME -c=kubenginx --limits=cpu=20m,memory=30Mi

    # Resume the Deployment
    kubectl rollout resume deployment/$DEPLOYMENT_NAME

    kubectl rollout history deployment/$DEPLOYMENT_NAME

fi
