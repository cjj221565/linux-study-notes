# 本项目使用 Docker Compose 一键部署 LNMP 环境，包含 Nginx、PHP-FPM、MySQL8.0，附带数据库自动备份。

>技术栈：Linux、Docker、Docker Compose、Nginx、MySQL、Shell、Crontab

>项目描述：
>在 Linux 虚拟机环境，使用 Docker-Compose 编排 Nginx、PHP、MySQL 容器搭建 LNMP 网站服务；编写 Shell 脚本实现 MySQL 数据库备份，配置 Crontab 定时任务每日自动备份，自动清理 7 天过期备份文件；实操排查端口冲突、文件权限、容器启动异常等故障；项目托管于 GitHub，包含完整部署文档、操作截图和排错记录。
## docker-compose.yml 文件结构及解析

```bash
 docker-compose.yml  四大框架
 version: '3.7'
 services:    # 核心：写所有容器服务
   服务名:
     image:
     restart: 容器崩了想自动重启
     env_file: 环境变量 需要传参数 密码等
     ports: 端口 宿主机端口：容器端口 外部访问
     volumes: 挂载 
     networks:
     depends_on: 依赖关系 多个容器有先后启动关系

 networks:    # 可选：自定义网络  多个容器互相访问，想方便通信 
 volumes:     # 可选：命名数据卷  服务里加了volumes 外面也要加
```

volumes：绑定挂载 (bind mount) 和 命名卷 (named volume) 的区别 & 使用场景
>1.✅绑定挂载（bind mount）
>写法例子：./html:/usr/share/nginx/html
>含义：把宿主机你自己指定的目录 / 文件，直接映射到容器里面。宿主机上修改文件，容器内同步变化。
>适合放：配置文件、网站代码（nginx.conf、html 网页），你需要在宿主机直接编辑修改。
>缺点：依赖宿主机的目录；宿主机目录权限问题容易踩坑。

>2.✅命名卷（named volume）
>写法例子：mysql-data:/var/lib/mysql，yml 底部要声明volumes: mysql-data:
>含义：Docker 自己管理的一块存储空间，放在 docker 的专属目录，不用你关心宿主机真实路径。
>适合放：数据库数据（mysql），纯持久化数据，不需要你手动进去改文件。
>优点：docker 自动管理，权限稳定，删除容器数据不会丢。
>一句话总结：
>要自己编辑修改的文件（代码、配置）用绑定挂载；
>只用来存数据、不需要手动改（数据库）用命名卷。

>总结：分为绑定挂载和命名卷。绑定挂载映射宿主机指定目录，适合存放需要手动编辑的配置、网页代码；命名卷由 Docker 管理，适合存放数据库这类持久化数据。

depends_on 有什么坑
>depends_on 只能控制【容器启动的先后顺序】，不能等容器内部的服务完全就绪！
>坑点：
>容器刚启动，里面的软件还在初始化，后面的服务就直接去连接，会报连接失败。
>面试话术：depends_on 仅控制容器启动顺序，不等待应用就绪。生产环境一般要写健康检查或者重试逻辑。



## nginx.conf 文件结构及解析

```bash
server {
    listen 80; #端口号
    server_name localhost; #站点名称
    root #容器内网页目录;
    index index.php index.html; # index 默认首页文件

    location ~ \.php$ {
        fastcgi_pass php:9000; # fastcgi_pass 服务名：端口
        #下面几行直接复制固定模板，几乎永远不用改
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

为什么 fastcgi_pass 写php:9000，不写 IP？
>在 docker compose 的同一个网络中，Docker 自带 DNS，服务名可以直接解析容器 IP，不需要写死 IP，容器重建 IP 变动也不用修改配置。

## backup.sh 备份文件
```bash
#!/bin/bash
# 声明脚本解释器，代表使用bash执行这个shell脚本，必须写在第一行
# backup.sh MySQL备份脚本 注释，说明脚本用途
BACKUP_DIR="./mysql-backup"
# 变量：备份文件存放目录，当前目录下mysql-backup文件夹
DATE=$(date +%Y%m%d_%H%M%S)
# 变量：获取当前时间，格式：年日月_时分秒，用来给备份文件命名，防止重名
DB_NAME="testdb"
# 变量：要备份的数据库名，和.env里MYSQL_DATABASE保持一致
DB_USER="root"
# 变量：数据库登录账号
DB_PASS="Admin@123456"
# 变量：数据库密码，和.env的MYSQL_ROOT_PASSWORD保持一致

# 创建备份目录
mkdir -p ${BACKUP_DIR}
# -p：目录不存在就新建；目录已存在不会报错
# 导出数据库
docker exec lnmp-mysql mysqldump -u${DB_USER} -p${DB_PASS} ${DB_NAME} > ${BACKUP_DIR}/db_${DATE}.sql
# docker exec lnmp-mysql：进入名字叫lnmp-mysql的容器内执行命令
# mysqldump：mysql自带数据库导出工具，用来备份
# > 重定向符号：把导出的数据写入sql文件
# db_${DATE}.sql：最终备份文件名，带时间戳

# 删除7天前旧备份，节省磁盘
find ${BACKUP_DIR} -name "db_*.sql" -mtime +7 -delete
# find 查找文件；-name匹配文件名db_开头 .sql结尾
# -mtime +7：文件修改时间超过7天；-delete找到后直接删除

echo "数据库备份完成: db_${DATE}.sql"
# 打印提示信息，告知备份成功，输出备份文件名
```

