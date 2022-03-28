* Homework
* In Minikube in namespace kube-system, there are many different pods running. Your task is to figure out who creates them, and who makes sure they are running (restores them after deletion)
```
PS C:\Users\Admin\desktop\2> kubectl describe pods -n kube-system | Select-String "Controlled By", "^Name:"

Name:                 coredns-64897985d-zhzmt
Controlled By:  ReplicaSet/coredns-64897985d
Name:                 etcd-minikube
Controlled By:  Node/minikube
Name:                 kube-apiserver-minikube
Controlled By:  Node/minikube
Name:                 kube-controller-manager-minikube
Controlled By:  Node/minikube
Name:                 kube-proxy-dlfzv
Controlled By:  DaemonSet/kube-proxy
Name:                 kube-scheduler-minikube
Controlled By:  Node/minikube
Name:                 metrics-server-6cd5c97f5d-k85m9
Controlled By:  ReplicaSet/metrics-server-6cd5c97f5d
Name:                 metrics-server-847dcc659d-rbdj6
Controlled By:  ReplicaSet/metrics-server-847dcc659d
Name:         storage-provisioner
```

* Implement Canary deployment of an application via Ingress. Traffic to canary deployment should be redirected if you add "canary:always" in the header, otherwise it should go to regular deployment. Set to redirect a percentage of traffic to canary deployment.
canary.yaml