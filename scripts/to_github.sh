#!/bin/bash

# XML文件处理脚本

# 定义输入和输出文件
input_file="$1"
output_file="$1.github"

# awk处理程序
awk '
BEGIN { FS = "[ \t]*[=][ \t]*"; OFS = "=" }
/<project/ && /name="/ {
    # 提取整个标签内容
    line = $0
    
    # 检查name值是否包含斜杠
    if (match(line, /name=["][^"]*\/[^"]*["]/)) {
        # 提取原始name值(带引号)
        name_attr = substr(line, RSTART + 5, RLENGTH - 5)
        gsub(/"/, "", name_attr) # 去掉引号只留值
        
        # (a)创建path属性字符串(带原值)
        path_attr = "path=\"" name_attr "\""
        
        # (b)修改name值中的/为-
        new_name = name_attr
        gsub(/\//, "-", new_name)
        new_name_attr = "name=\"" new_name "\""
        
        # (c)替换原name属性
        sub(/name=["][^"]*["]/, new_name_attr, line)
        
        # (d)在第一个/>前插入path属性(确保在name后)

        if (!match(line, /path="/)) {
        	if (match(line, /[^>]*>/)) {
            		pre = substr(line, RSTART, RLENGTH -2)
            		post = substr(line, RSTART + RLENGTH -2)
            		line = pre " " path_attr post
        	}
	}
        
        print line
        next
    }
}
{ print } # 其他行原样输出
' "$input_file" > "$output_file"

mv $output_file $input_file
echo "处理完成。"
