source $(dirname "$0")/set-credentials.sh

#kubectl exec -it my-first-pod -- /bin/bash

kubectl exec -it my-first-pod -- env
kubectl exec -it my-first-pod -- ls
kubectl exec -it my-first-pod -- cat /usr/share/nginx/html/index.html


