# Docker collection

Collection of docker-related snippets, commands and [example of Dockerfile optimization](dockerfile_optimization/README.md)



##### Simple run container with mount current volume

```shell script
docker run -it -v $(pwd):/app deployer.azurecr.io/helm-lux:staging
```

##### Containers list sorted by name

```shell script
docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Status}}\t{{.Ports}}" | (read -r; printf "%s\n" "$REPLY"; sort -k 1 )
```

##### Containers list within their Name, Image and IP address

```shell script
docker inspect -f '{{.Name}} - {{.Config.Hostname}} - {{.Config.Image}} - {{.NetworkSettings.IPAddress }}' $(docker ps -q)
```

##### Generate Dockerfile by Docker image

```shell script
alias dfimage="docker run -v /var/run/docker.sock:/var/run/docker.sock --rm alpine/dfimage"
dfimage -sV=1.36 docker.elastic.co/beats/filebeat:7.5.1
```

##### Measure build time

```shell script
TIMEFORMAT='%R sec'; time { docker build --target prod -f docker/php-fpm/Dockerfile -t testsize-php-0:prod . > /dev/null ; }
```

##### Prune unused images via contained

Using `docker`

```shell script
# for removing dangling and ununsed images ('unused' means "images not referenced by any container")
docker image prune -a
# will delete all dangling data (containers, networks, and images). Using -a option will delete all unused images (not just dangling)
docker system prune --all
#
df -h | grep '^/dev/' && docker image prune -a && df -h | grep '^/dev/'
```


Using `containerd`

```shell script
crictl rmi --prune
#
df -h | grep '^/dev/' && crictl rmi --prune && df -h | grep '^/dev/'
```
