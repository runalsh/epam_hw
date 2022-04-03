* We published minio "outside" using nodePort. Do the same but using ingress - ingress.yaml
* Publish minio via ingress so that minio by ip_minikube and nginx returning hostname (previous job) by path ip_minikube/web are available at the same time -  deployment.yaml

![image](https://raw.githubusercontent.com/runalsh/epam_hw/main/kuber/3/2.PNG)

* Create deploy with emptyDir save data to mountPoint emptyDir, delete pods, check data - service.yaml

* Full log of working with task - log.txt











