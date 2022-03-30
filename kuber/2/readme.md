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

```
C:\Users\Admin\Desktop\education-main\task_2>kubectl apply -f home-deployment.yaml
deployment.apps/web-homework created

C:\Users\Admin\Desktop\education-main\task_2>kubectl apply -f home-service_template.yaml
service/web-homework created

C:\Users\Admin\Desktop\education-main\task_2>kubectl apply -f home-nginx-configmap.yaml
configmap/nginx-configmap-homework created

C:\Users\Admin\Desktop\education-main\task_2>kubectl apply -f home-ingress.yaml
ingress.networking.k8s.io/ingress-web-homework created

C:\Users\Admin\Desktop\education-main\task_2>kubectl get pod
NAME                            READY   STATUS    RESTARTS   AGE
nginx                           1/1     Running   0          27m
web-6745ffd5c8-4vtt7            1/1     Running   0          25m
web-6745ffd5c8-g4wp5            1/1     Running   0          25m
web-6745ffd5c8-xvb7v            1/1     Running   0          25m
web-homework-5488644856-6q646   1/1     Running   0          6m35s
web-homework-5488644856-hq8f4   1/1     Running   0          6m35s
web-homework-5488644856-whd7h   1/1     Running   0          6m35s

C:\Users\Admin\Desktop\education-main\task_2>F:\VB\curl\curl 192.168.59.102 -H "canary:always"
web-homework-5488644856-6q646
 homework
C:\Users\Admin\Desktop\education-main\task_2>F:\VB\curl\curl 192.168.59.102 -H "canary:always"
web-homework-5488644856-whd7h
 homework
C:\Users\Admin\Desktop\education-main\task_2>F:\VB\curl\curl 192.168.59.102 -H "canary:always"
web-homework-5488644856-hq8f4
 homework
C:\Users\Admin\Desktop\education-main\task_2>F:\VB\curl\curl 192.168.59.102 -H "canary:always"
web-homework-5488644856-6q646
 homework
 
 C:\Users\Admin\Desktop\education-main\task_2>curl 192.168.59.102
web-6745ffd5c8-4vtt7

C:\Users\Admin\Desktop\education-main\task_2>curl 192.168.59.102
web-6745ffd5c8-g4wp5

C:\Users\Admin\Desktop\education-main\task_2>curl 192.168.59.102
web-6745ffd5c8-xvb7v

C:\Users\Admin\Desktop\education-main\task_2>curl 192.168.59.102
web-6745ffd5c8-xvb7v
```


* Full log of working with task - log.txt
* Some screens from dashboard - pres.pptx
