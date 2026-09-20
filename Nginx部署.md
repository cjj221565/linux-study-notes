# Nginx部署

## Nginx介绍
Nginx高性能Web服务 反向代理服务器

作用：1. 托管静态网页（html/css/js） 2. 反向代理 把PHP请求发给PHP-FPM 3. 可拓展负载均衡

默认端口：80(http)   443(https)

## 2种部署方式

1. 宿主机直接安装（centos）
```bash
# 安装
yum install nginx -y
# 启动 开机自启动
yum start nginx
yum enable nginx
# 查看状态
yum status nginx
```

> 相关文件：
> 1. 主配置文件 /etc/nginx/nginx.conf
> 2. 站点配置文件 /etc/nginx/conf.d
> 3. 默认网站根目录 /usr/share/nginx/html
> 查看端口： ss -tulnp | grep nginx
> 查看日志： journalctl -u nginx -f

2. Docker-compose 部署
docker-compose.yml文件部署

```bash
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./www:/usr/share/nginx/html
    depends_on:
      - php
```

> 字段说明：
> 1. port:"80:80": 宿主机80端口映射容器内80端口 容器产生端口冲突
> 2. volumes:挂载 宿主机目录和容器目录映射 不用进入容器 直接在宿主机修改配置 网页文件
> 3. depends_on: 控制容器启动顺序 先启动php容器 再启动nginx 只是顺序 不保证php服务就绪

启动命令（在yml文件所在目录下）
```bash
# 后台启动容器
docker-compose up -d
# 实时查看nginx容器日志
docker-compose logs -f nginx
```

## Nginx站点部署 conf.d/default.conf
```bash
server {
    listen 80;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html index.php;

    # LNMP核心：匹配php请求转发给php-fpm
    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

修改配置后的操作（必做）
```bash
# 校验配置语法，防止写错导致nginx无法启动
docker exec lnmp-nginx nginx -t
# 平滑重载配置，不中断现有连接
docker exec lnmp-nginx nginx -s reload
```

> nginx - t 校验配置文件语法是否正确 避免重载后Nginx服务异常

## Nginx常见报错 & 排错流程

### 1.网页无法访问
```bash
ss -tulnp | grep :80
```

没有LISTEN 容器没有启动 查看容器日志/排查端口冲突
有LISTEN 防火墙firewalld是否放行80端口

### 2.页面403
权限问题 Nginx挂载目录权限不对/进程没有读取网页文件的权限/首页文件不存在

### 3.访问PHP直接下载 不解析PHP
Nginx缺少PHP转发的location配置

### 4.502 Bad Gateway
Nginx无法连接 PHP-FPM
排查方向：php容器未启动/php未监听9000端口/fastcgi_pass地址写错 查看nginx日志定位报错
