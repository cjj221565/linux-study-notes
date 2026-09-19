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