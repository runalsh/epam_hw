* We published minio "outside" using nodePort. Do the same but using ingress - ingress.yaml

![image](https://raw.githubusercontent.com/runalsh/epam_hw/main/kuber/3/1.PNG)

* Publish minio via ingress so that minio by ip_minikube and nginx returning hostname (previous job) by path ip_minikube/web are available at the same time -  deployment.yaml and nginx.yaml and service.yaml

![image](https://raw.githubusercontent.com/runalsh/epam_hw/main/kuber/3/2.PNG)

* Create deploy with emptyDir save data to mountPoint emptyDir, delete pods, check data -  nginx.yaml

* Full log of working with task - log.txt
```
lets connect to pod

kubectl exec -it minio-94fd47554-xq75z bash
[root@minio-94fd47554-xq75z /]# cd blablabla
[root@minio-94fd47554-xq75z blablabla]# ls -la
total 8
drwxrwxrwx 2 root root 4096 Apr  3 15:39 .
drwxr-xr-x 1 root root 4096 Apr  3 15:39 ..

create the file

[root@minio-94fd47554-xq75z blablabla]# echo privet > privet.txt
[root@minio-94fd47554-xq75z blablabla]# ls -la
total 12
drwxrwxrwx 2 root root 4096 Apr  3 15:44 .
drwxr-xr-x 1 root root 4096 Apr  3 15:39 ..
-rw-r--r-- 1 root root    7 Apr  3 15:44 privet.txt
[root@minio-94fd47554-xq75z blablabla]# cat privet.txt
privet

stop container

[root@minio-94fd47554-xq75z blablabla]# kill nginx
bash: kill: nginx: arguments must be process or job IDs

[root@minio-94fd47554-xq75z blablabla]# kill 1
[root@minio-94fd47554-xq75z blablabla]# command terminated with exit code 137











