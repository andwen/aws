#!/usr/bin/env bash
#https://docs.aws.amazon.com/zh_cn/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration
#By：onepve https://blog.wxlost.com/lightsailm.html

#颜色
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"

#核心! AWS KEY
AccessKeyId="你的AWS参数"
SecretKey="你的AWS参数"
#核心! CloudFlare
CloudFlare_Api="你的CloudFlare API Key参数"
auth_email="onepve@gmail.com"
auth_key="你的CloudFlare API Key参数,和上面一致" # found in cloudflare account settings


#执行参数需要写在脚本上面等待调用
function Start_default(){
region="ap-northeast-1"	#机器地区英文编码,默认:日本
zone_name="name.com"  #你的域名,格式:name.com
record_name="xxx.name.com" #你的域名,格式:xxx.name.com
configure

#入口核心! 变量部分-这里为单账号多区域.其他需求自行改造脚本
aws_Name="Debian-512MB-Tokyo-1" #你的机器名字
aws_Ip="StaticIP-Tokyo-1"   #你的机器静态IP名,如果第一次使用无效请手动创建一个

getvpsip
CloudFlare
clear_log
}

#第二台机器参考参数,执行命令:bash aws_changed_ip.sh Seoul
function Start_Seoul(){
region="ap-northeast-2"	#韩国
zone_name="reg.ru"
record_name="awskor1.reg.ru"
configure

#入口核心! 变量部分-这里为单账号多区域.其他需求自行改造脚本
aws_Name="Debian-512MB-Seoul-1"
aws_Ip="StaticIP-Seoul-1"

getvpsip
CloudFlare
clear_log
}
#↑第二台机器参考参数结尾


function getvpsip(){
echo -e "${Green_font_prefix}删除: ${Font_color_suffix} 旧静态IP"
# 删除旧 静态IP
aws lightsail release-static-ip --static-ip-name ${aws_Ip} >/tmp/aws/old_ip.logs
# 获取新 静态IP
echo -e "${Green_font_prefix}添加: ${Font_color_suffix} 新静态IP"
aws lightsail allocate-static-ip --static-ip-name ${aws_Ip} >/tmp/aws/new_ip.logs
# 绑定 静态IP
echo -e "${Green_font_prefix}绑定: ${Font_color_suffix} 静态IP到机器"
aws lightsail  attach-static-ip --static-ip-name ${aws_Ip} --instance-name ${aws_Name} >/tmp/aws/set_ip.logs
# 获取最新IP
aws_New_Ip=`aws lightsail get-static-ips | grep ipAddress |grep -o -P "(\d+\.)(\d+\.)(\d+\.)\d+"`
echo -e "${Green_font_prefix}新IP ${Font_color_suffix} $aws_New_Ip"
}

#CloudFlare
function CloudFlare(){
echo -e "${Green_font_prefix}域名: ${Font_color_suffix} 解析开始"
ip=$aws_New_Ip


zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')

update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\"}")


if [[ $update == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    echo -e "$message"
    exit 1 
else
    message="${Green_font_prefix}域名: ${Font_color_suffix} $record_name 解析为：$ip"
    echo -e "$message"
fi
echo -e "${Green_font_prefix}域名: ${Font_color_suffix} 解析完成"
}

function clear_log(){
rm -rf /tmp/aws/*
exit 0
killall `basename $0`	#appnode执行本脚本自杀用.效果未测试
}

function configure(){
#查看定义的参数配置命令为:
#cat ~/.aws/config
#cat ~/.aws/credentials

aws configure <<EOF
${AccessKeyId}
${SecretKey}
${region}

EOF

#clear
echo -e " "
echo -e "${Green_font_prefix}API: ${Font_color_suffix} 设置完成"
}
#尾部脚本入口-------------
#检查执行入口
if [ $# -eq 0 -o $# -gt 2 ]; then
	echo -e " - Usage: ${Green_font_prefix}bash $0${Font_color_suffix} ${Red_font_prefix}default${Font_color_suffix}"; exit 1;
fi

if [ $# -eq 2 -a "$2" = '-p' ]; then	#判断 删除AWS配置 此处代码用处不大.可删
	rm -rf ~/.aws/config
	rm -rf ~/.aws/credentials
fi

#判断式菜单
	#clear
	echo -e " ${Green_font_prefix}AWS lightsail管理IP${Font_color_suffix} ${Red_font_prefix}[v1.2]${Font_color_suffix}
  --- 欢迎使用 ----
  "
#	echo -e "你当前执行换IP的命令为${Green_font_prefix} $1 ${Font_color_suffix},继续吗？${Green_font_prefix}[Y/n]${Font_color_suffix}"
#	read -p "(默认: y):" yn
#	[[ -z "${yn}" ]] && yn="y"
#	if [[ ${yn} == [Yy] ]]; then
#	echo -e "开始执行换IP过程!"
#	else
#	echo && echo "已取消本次操作..." && exit 0;
#	fi

#正式执行入口
echo -e "开始执行[$1]..."
Start_$1	#执行参数
