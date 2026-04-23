# truenas_custom_script
此脚本做了以下几件事  
  1. 安装huawei2000 ups驱动（需要libmodbus5库）  
  2. 修改catalog使用国内加速网站  

将脚本设置为开关机脚本，脚本会在每次系统更新后执行（准确说是last_version.txt缺失或与当前系统版本不一致时执行）  
TrueNAS 高级设置 -> 开关机脚本 -> 初始化后期  
