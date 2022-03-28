* Create users deploy_view and deploy_edit. Give the user deploy_view rights only to view deployments, pods. Give the user deploy_edit full rights to the objects deployments, pods. 
```
openssl genrsa -out deploy_view.key 2048
openssl req -new -key deploy_view.key -out deploy_view.csr -subj "/CN=deploy_view"
openssl x509 -req -in deploy_view.csr -CA F:\VB\minikube_profile\.minikube\ca.crt -CAkey F:\VB\minikube_profile\.minikube\ca.key -CAcreateserial -out deploy_view.crt -days 500
Certificate request self-signature ok
subject=CN = deploy_view
kubectl config set-credentials deploy_view --client-certificate=deploy_view.crt --client-key=deploy_view.key
User "deploy_view" set.
kubectl config set-context deploy_view --cluster=minikube --user=deploy_view
Context "deploy_view" created.
kubectl config use-context deploy_view
Switched to context "deploy_view".
kubectl get node
Error from server (Forbidden): nodes is forbidden: User "deploy_view" cannot list resource "nodes" in API group "" at the cluster scope
kubectl config use-context minikube
Switched to context "minikube".
kubectl apply -f dep_view.yaml
clusterrole.rbac.authorization.k8s.io/deploy_view created
clusterrolebinding.rbac.authorization.k8s.io/deploy_view created
clusterrole.rbac.authorization.k8s.io/deploy_edit created
clusterrolebinding.rbac.authorization.k8s.io/deploy_edit created
kubectl get node
NAME       STATUS   ROLES                  AGE   VERSION
minikube   Ready    control-plane,master   4d    v1.23.3
```
* Create namespace prod. Create users prod_admin, prod_view. Give the user prod_admin admin rights on ns prod, give the user prod_view only view rights on namespace prod.
 ```
kubectl create namespace prod
namespace/prod created
...
kubectl apply -f prod.yaml
rolebinding.rbac.authorization.k8s.io/view created
rolebinding.rbac.authorization.k8s.io/prod created
...
```
* Create a serviceAccount sa-namespace-admin. Grant full rights to namespace default. Create context, authorize using the created sa, check accesses.
 ```
* kubectl auth can-i get pods --as=system:serviceaccount:default:sa-namespace-admin
no
kubectl auth can-i get pods --as=system:serviceaccount:prod:sa-namespace-admin
no
kubectl apply -f service.yaml
serviceaccount/sa-namespace-admin created
rolebinding.rbac.authorization.k8s.io/sa-namespace-admin created
kubectl auth can-i get pods --as=system:serviceaccount:default:sa-namespace-admin
yes
kubectl auth can-i get pods --as=system:serviceaccount:prod:sa-namespace-admin
no
```

* Full log of working with task - log.txt
