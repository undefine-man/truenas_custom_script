#!/bin/bash

# --- 1. 版本校验 ---
VERSION_FILE="/mnt/storage/share/truenas/last_version.txt"
CURRENT_VERSION=$(cat /etc/version)
mkdir -p "$(dirname "$VERSION_FILE")"

# --- 版本校验逻辑 ---
if [ -f "$VERSION_FILE" ]; then
    LAST_VERSION=$(cat "$VERSION_FILE")
else
    LAST_VERSION="none"
fi

if [ "$CURRENT_VERSION" == "$LAST_VERSION" ]; then
    echo "系统版本未变 ($CURRENT_VERSION)，跳过执行逻辑。"
    exit 0
fi

echo "检测到系统更新或首次运行！"
echo "旧版本: $LAST_VERSION"
echo "新版本: $CURRENT_VERSION"
# --- 2. 环境准备 ---
systemd-sysext unmerge
install-dev-tools

# --- 3. 驱动与依赖部署 ---
apt update && apt install -y libmodbus5
cp /mnt/storage/share/truenas/huawei-ups2000 /usr/lib/nut/huawei-ups2000
chown root:root /usr/lib/nut/huawei-ups2000
chmod 755 /usr/lib/nut/huawei-ups2000

# --- 4. 修改驱动列表 (精确匹配完整条目) ---
DRIVER_LIST="/usr/share/nut/driver.list"
# 这是你完整要插入的内容
DRIVER_ITEM="\"Huawei\"\t\"ups\"\t\"3\"\t\"UPS2000-G and UPS2000-A series\"\t\"\"\t\"huawei-ups2000\""

# 只有文件里完全没这一行时，才在 UPS5000-E 后面插入
if ! grep -qP "$DRIVER_ITEM" "$DRIVER_LIST"; then
    sed -i "/\"Huawei\"\t\"ups\"\t\"4\"\t\"UPS5000-E\"/a $DRIVER_ITEM" "$DRIVER_LIST"
    echo "未发现huawei-2000驱动条目，已插入新配置。"
else
    echo "huawei-2000驱动条目已存在，跳过。"
fi

# --- 5. 修改中间件镜像 ---
CATALOG_FILE="/usr/lib/python3/dist-packages/middlewared/plugins/catalog/utils.py"
if [ -f "$CATALOG_FILE" ]; then
    sed -i 's|https://github.com/truenas/apps|https://gh.xmly.dev/https://github.com/truenas/apps|g' "$CATALOG_FILE"
    echo "已修改catalog镜像地址。"
fi

# --- 6. 完成合并并记录版本 ---
systemd-sysext merge
echo "$CURRENT_VERSION" > "$VERSION_FILE"

systemctl restart nut-server
midclt call catalog.sync
