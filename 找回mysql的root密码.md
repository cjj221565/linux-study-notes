# 找回mysql的root密码

**忘记了mysql的root密码 登录不进去**

```bash
mysql -u root -p
```

1. 进入文件 添加一段话代表跳过权限 并关闭重启

```bash
vim /etc/my.cnf
skip-grant-tables
service mysqld restart
```

1. 进入mysql数据库 此时不需要密码 输空就能进去 查看数据库 进入mysql数据库 查看表 进入user表 里面有个字段authentication_string意思为原生密码
修改这个字段为新的密码 刷新后即可exit退出

```bash
mysql -u root -p
show databases;
use mysql;
show tables;
desc user;
update user set authentication_string=passwd("你的密码") where user='root';
flush privileges;
```

1. 再次进入文件 将skip-grant-tables注释掉代表恢复原来不跳过权限 退出后重启mysql服务

```bash
skip-grant-tables
service mysqld restart
```

**此时登录mysql就是新密码**
