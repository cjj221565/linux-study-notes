# Docker Compose LNMP + 自动备份 完整实操步骤
> LNMP = Linux + Nginx + MySQL + PHP
> 环境：虚拟机（Ubuntu / CentOS 都行），全程免费，做完上传 GitHub，写 README 放进简历
> 项目包含：一键启动 LNMP、PHP 网页访问、数据库、数据库自动备份脚本，还有故障点.

## 一、先安装 Docker + Docker Compose
Ubuntu (推荐)

```bash
# 更新软件源
sudo apt update
# 安装docker
sudo apt install docker.io -y
# 启动并设置开机自启
sudo systemctl start docker
sudo systemctl enable docker
# 把当前用户加入docker组（免sudo，重要！）
sudo usermod -aG docker $USER
```
> 注意：加入用户组后，重新登录虚拟机生效

> 注意！docker.io官方版不提供 docker-compose-plugin 包 所以需要手动安装独立旧版 docker-compose（V1 & V2）
> V1 V2 区别：V1 已经停止维护，但是跑项目、学习原理 V2 现在生产环境主流；缺点：要把现有 Docker 删掉重装，多花时间
```bash
# V1
sudo apt update
sudo apt install docker-compose -y
# V2
# 1.卸载当时的docker.io
sudo apt remove docker.io -y
# 2.添加docker官方源
# 3.安装 docker-ce + docker-compose-plugin
```

安装 docker-compose 插件 (V1)
```bash
sudo apt install docker-compose -y 
# 验证安装
docker-compose --version
```

## 二、新建项目文件夹 准备文件

```bash
#创建项目目录
mkdir lnmp-compose
cd lnmp-compose
```

在lnmp-compose文件夹里面 新建这四个文件
1. docker-compose.yml 【核心编排文件】

2. nginx.conf Nginx 配置

3. backup.sh 数据库自动备份脚本

4. .env 存放密码等变量（方便管理）

 .env文件 环境变量文件

```bash
env
MYSQL_ROOT_PASSWORD=Admin@123456
MYSQL_DATABASE=testdb
MYSQL_USER=testuser
MYSQL_PASSWORD=User@123456
```

docker-compose.yml 文件 用来一次性编排、管理多个 Docker 容器

```bash
yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: lnmp-mysql
    env_file: .env
    volumes:
      - mysql-data:/var/lib/mysql
      - ./mysql-backup:/backup
    ports:
      - "3306:3306"
    restart: always

  nginx:
    image: nginx:alpine
    container_name: lnmp-nginx
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php
    restart: always

  php:
    image: php:fpm-alpine
    container_name: lnmp-php
    volumes:
      - ./html:/usr/share/nginx/html
    depends_on:
      - mysql
    restart: always

volumes:
  mysql-data:
```

nginx.conf 文件 Nginx 的站点配置，作用：接收浏览器的请求，区分静态文件和 PHP 动态请求

```bash
nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.php index.html;

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```
>在 html 目录生成 index.php 文件，文件内容是<?php phpinfo(); ?>，用来等下浏览器访问，测试 LNMP 整套环境是否跑通。

新建网页目录 写php测试页
```bash
mkdir html
echo "<?php phpinfo(); ?>" > html/index.php
```

backup.sh 文件 数据库自动备份脚本

```bash
bash
#!/bin/bash
# backup.sh MySQL备份脚本
BACKUP_DIR="./mysql-backup"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="testdb"
DB_USER="root"
DB_PASS="Admin@123456"

# 创建备份目录
mkdir -p ${BACKUP_DIR}
# 导出数据库
docker exec lnmp-mysql mysqldump -u${DB_USER} -p${DB_PASS} ${DB_NAME} > ${BACKUP_DIR}/db_${DATE}.sql

# 删除7天前旧备份，节省磁盘
find ${BACKUP_DIR} -name "db_*.sql" -mtime +7 -delete
echo "数据库备份完成: db_${DATE}.sql"
```

给脚本权限

```bash
bash
chmod +x backup.sh
# 手动测试跑一次备份
./backup.sh
```

一键启动环境
```bash
# 在 lnmp-compose目录下执行
docker compose up -d
```

>如果报错 可以单独拉取

```bash
docker pull mysql:8.0
docker pull nginx:alpine
docker pull php:fpm
```

测试备份
```bash
./backup.sh
```

>执行完可以查看文件夹里面会生成.sql数据库备份文件

```bash
ls mysql-backup/
```

设置定时自动备份 （crontab）
```bash
# 打开定时任务
crontab -e
0 2 * * * /home/ubuntu/lnmp-compose/backup.sh >> /home/ubuntu/lnmp-compose/backup.log 2>&1
# 0 2 * * * /home/你的用户名/lnmp-compose/backup.sh >> /home/你的用户名/lnmp-compose/backup.log
```
