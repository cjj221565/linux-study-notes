# Docker-compose 部署gitea托管平台

>centos7虚拟机
>Docker环境
>gitea是自建小型的github

## 1. 创建gitea目录 并进入
```
mkdir -p /opt/gitea && cd /opt/gitea
pwd
```
## 2. 创建.env环境文件
```
TZ=Asia/Shanghai
GITEA__database__DB_TYPE=mysql
GITEA__database__HOST=db:3306
GITEA__database__NAME=gitea
GITEA__database__USER=gitea
GITEA__database__PASSWD=gitea123
MYSQL_ROOT_PASSWORD=root123
MYSQL_DATABASE=gitea
MYSQL_USER=gitea
MYSQL_PASSWORD=gitea123
```
## 3. 创建 docker-compose.yml文件
```
version: "3"

networks:
  gitea:
    external: false

services:
  server:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=mysql
      - GITEA__database__HOST=db:3306
      - GITEA__database__NAME=gitea
      - GITEA__database__USER=gitea
      - GITEA__database__PASSWD=gitea123
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "222:22"
    depends_on:
      - db

  db:
    image: mysql:8
    container_name: gitea-mysql
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=root123
      - MYSQL_DATABASE=gitea
      - MYSQL_USER=gitea
      - MYSQL_PASSWORD=gitea123
    networks:
      - gitea
    volumes:
      - ./mysql:/var/lib/mysql
```
## 4. 启动
```
docker compose up -d
```
## 5. 报错 
> Error response from daemon: Get "https://registry-1.docker.io/v2/": dial tcp 108.160.169.46:443: i/o timeout
>意思：连不上Docker的官方镜像仓库 下载超时
### 1.创建/修改Docker配置文件 
```
vim /etc/docker/daemon.json
```
### 2. 编辑
```
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://dockerproxy.com",
    "https://docker.nju.edu.cn"
  ]
}
```
### 3. 重启Docker服务
```
systemctl daemon-reload
systemctl restart docker
```
### 4. 重新拉起gitea
```
docker compose up -d
```
## 报错
> ✘ db Error                   Get "https://registry-1.docker.io/v2...          33.4s
Error response from daemon: Get "https://registry-1.docker.io/v2/": net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
>原因：MySQL 8 的镜像比较大（大概 150MB+），网速不稳定的时候容易断
### 继续拉取即可
```
docker compose up -d
```
## 6.查看进程
```
docker ps
```
>看到 `gitea` 和 `gitea-mysql` 这两行，而且 `STATUS` 那一列显示的是 **`Up`** 而不是 `Restarting` 或 `Exited`。如果都是 `Up`，说明服务活得非常健康
## 7. 浏览器访问 http://你的虚拟机IP:3000
### 1.数据库设置保持不动
### 2. 管理员账号设置 密码一定要记住
### 3. 勾选Only administrators can create user accounts
### 4. 立即安装
