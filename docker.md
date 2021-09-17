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
