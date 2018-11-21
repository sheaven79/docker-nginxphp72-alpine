# Nginx + PHP 7.2 Docker
## 系统要求
Docker Engine release 17.04.0+

## 容器包含组件

```
基于 php:7.2-fpm-alpine 基础镜像
PHP 7.2 latest 版，除基本拓展外还增加了 gd zip pdo pdo_mysql 拓展
Nginx 1.14.1，docker build 时 alpine linux apk 安装的最新版
Redis 4.0.11，同上
Composer，已替换国内镜像
其它：supervisor git bash openssh-client
```

## 项目克隆

```
$ mkdir ~/docker
$ cd ~/docker
$ git clone git@git.hoge.cn:dockerfile/nginxphp72-alpine.git
```

## 构建

```
$ cd nginxphp72-alpine
$ docker build -t nginxphp72:alpine .
```

## 运行

```
$ docker run -d -p 80:80 --name web nginxphp72:alpine
```

## 访问

http://127.0.0.1 or http://sample.com

> 如果你要使用 http://sample.com 访问，请预先在本机 hosts 配 127.0.0.1 sample.com

可通过修改下面文件中的相关配置进行域名变更（修改后需要重新构建）

```
nginx/sample.conf
```

## 维护
* 停止容器： `docker stop web`

* 启动容器： `docker start web`

* 查看容器日志： `docker logs web`

* 进入 web 容器： `docker exec -it web ash`

## 清理

>!!!注意以下操作会清理全部 Docker 容器数据，并且无法恢复!!!

* 删除容器：`docker rm -f web`

* 删除 build 的镜像：`docker rmi nginxphp72:alpine`

# 高级运行方法
## 从本机目录映射 nginx 配置文件与 web 主目录

```
$ cd ~/docker
$ docker run -d \
	--name web \
    -v ~/docker/nginxphp72-alpine/nginx/nginx.conf:/etc/nginx/nginx.conf \
	-v ~/docker/nginxphp72-alpine/nginx/sample.conf:/etc/nginx/conf.d/default.conf \
	-v ~/docker/nginxphp72-alpine/html:/var/www/html \
	-p 80:80 \
    nginxphp72:alpine
```
> 上述方法运行后只需修改本机对应路径的文件就能实现同步更新容器内对应的文件

Nginx 主配置文件：`~/docker/nginxphp72-alpine/nginx/nginx.conf`

Nginx 站点配置文件：`~/docker/nginxphp72-alpine/nginx/sample.conf`

Nginx 站点路径：`~/docker/nginxphp72-alpine/html/`

> nginx 配置修改后可以通过 `docker exec web nginx -s reload` 或者 `docker restart web` 重启 nginx 或者容器来生效


## 与 Mysql 5.7 结合运行

### 先启动 mysql 容器

```
$ docker run -d \
	--name mysql \
	-e MYSQL_ROOT_PASSWORD=mypassword \
	-v mysqldata:/var/lib/mysql \
	mysql:5.7 \
	--character-set-server=utf8
```

> MySQL 容器启动后默认 data 目录为 volume 卷，如需使用本机路径请自行修改 -v mysqldata:/var/lib/mysql

MySQL `root` 密码为 `mypassword`

### 再启动 web 容器

```
$ docker run -d \
	--name web \
	--link mysql:db.mysql \
    -v ~/docker/nginxphp72-alpine/nginx/nginx.conf:/etc/nginx/nginx.conf \
	-v ~/docker/nginxphp72-alpine/nginx/sample.conf:/etc/nginx/conf.d/default.conf \
	-v ~/docker/nginxphp72-alpine/html:/var/www/html \
	-p 80:80 \
    nginxphp72:alpine
```

> PHP 中使用 db.mysql 来链接 mysql 容器，其它事项同 `从本机目录映射 nginx 配置文件与 web 主目录`