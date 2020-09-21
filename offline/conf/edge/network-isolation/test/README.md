kubectl apply -f test/hello.yaml
kubectl apply -f hello-service.yaml
kubectl apply -f hello-client.yaml

kubectl exec -it hello-d69784fc9-hsddf -c tcpdump -- ip addr
kubectl exec -it pod/samplepod1 -c samplepod -- wget -O - http://hello1
