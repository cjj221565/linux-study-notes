# 统计ip访问情况，要求分析nginx访问日志(access.log)，并找出访问页面数量在前2位的ip

1. 查看文件 并根据空格分隔输出第一部分排序整合 之后倒序输出前两位

```bash
cat access.log | awk -F ' ' '{print $1}'| sort | uniq -c | sort -nr | head -2
```

# 使用tcpdump监听本机，将来自ip 192.168.201.1,，tcp端口为22的数据，保存输出到tcpdump.log用作将来数据分析

1. 首先查看是否安装tcpdump

```bash
tcpdump
```

2. 查看是否能监听本机端口为22的数据

```bash
tcpdump -i ens33 host 192.168.201.1 and port 22
```

3. 重定向内容到想要保存的文件 可以查看

```bash
tcpdump -i ens33 host 192.168.201.1 and port 22 >> /opt/interview/tcpdump.log
cat /opt/interview/tcpdump.log
```
