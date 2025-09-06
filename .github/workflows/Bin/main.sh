#!/bin/bash
set -euo pipefail

# 全局变量
readonly GITHUB_ENV=${GITHUB_ENV:-".env"}
# readonly REPO_URL="https://github.com/Hivensafe/cloud_kernel_enable/main"
readonly DEMO_REPO="https://github.com/521141/Demo_kernel.git"
# readonly ANYKERNEL_REPO="https://github.com/showdo/AnyKernel3.git"
# readonly TG_CHANNEL="https://t.me/qdykernel"

# 检查环境
# check_environment() {
#     if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
#         echo "错误：检测到非 GitHub Actions 环境，禁止本地执行！"
#         exit 1
#     fi
# }

# # 检查远程状态
# check_remote_status() {
#     local flag
#     local version

#     flag=$(curl -fsSL "${REPO_URL}/enable.txt" | tr -d '\r\n') || {
#         echo "错误：无法获取启用标志"
#         exit 1
#     }

#     version=$(curl -fsSL "${REPO_URL}/main_version.txt" | tr -d '\r\n') || {
#         echo "错误：无法获取版本信息"
#         exit 1
#     }

#     if [ "$flag" != "on" ]; then
#         echo "错误：服务未启用，请联系作者"
#         echo "TG频道：${TG_CHANNEL}"
#         exit 1
#     fi

#     if [ "$version" != "10005" ]; then
#         echo "错误：分支已过期 (最新: ${version}，当前: 10005)"
#         echo "请同步上游更新"
#         echo "TG频道：${TG_CHANNEL}"
#         exit 1
#     fi
# }

# 设置LZ4配置
setup_lz4() {
    echo "正在设置LZ4配置..."
    # 克隆仓库
    if ! git clone "${DEMO_REPO}" --depth=1 &>/dev/null; then
        exit 1
    fi

    # 清理和复制文件
    rm -rf Demo_kernel/.git || true
    mkdir -p ./lib/lz4 ./include/linux

    if ! cp -r ./Demo_kernel/zram/lz4/* ./lib/lz4/; then
        echo "错误：复制lz4文件失败"
        exit 1
    fi

    if ! cp -r ./Demo_kernel/zram/include/linux/* ./include/linux/; then
        echo "错误：复制linux头文件失败"
        exit 1
    fi

    if ! cp ./Demo_kernel/zram/6.6/lz4_1.10.0.patch ./; then
        echo "错误：复制补丁文件失败"
        exit 1
    fi

    # 应用补丁
    if ! patch -p1 -F 3 --fuzz=5 < lz4_1.10.0.patch; then
        echo "警告：应用补丁时出现问题，但继续执行..."
    fi

    # 修改Makefile
    local makefile="fs/f2fs/Makefile"
    if [ ! -f "$makefile" ]; then
        echo "错误：找不到文件 ${makefile}"
        exit 1
    fi

    if ! grep -qF "f2fs-\$(CONFIG_F2FS_IOSTAT) += iostat.o" "$makefile"; then
        echo "f2fs-\$(CONFIG_F2FS_IOSTAT) += iostat.o" >>"$makefile"
        echo "已添加: f2fs-\$(CONFIG_F2FS_IOSTAT) += iostat.o"
    else
        echo "文件已经包含: f2fs-\$(CONFIG_F2FS_IOSTAT) += iostat.o"
    fi

    echo "LZ4配置完成"
}

# 设置GKI配置
setup_gki_config() {
    local defconfig="./common/arch/arm64/configs/gki_defconfig"

    if [ ! -f "$defconfig" ]; then
        echo "错误：找不到gki_defconfig文件"
        exit 1
    fi

    echo "正在配置GKI..."

    # 基本配置
    cat <<EOF >>"$defconfig"
CONFIG_KSU=y
CONFIG_KSU_SUSFS_SUS_SU=n
CONFIG_KSU_MANUAL_HOOK=y
CONFIG_KPM=y
CONFIG_CRYPTO_LZ4=y
CONFIG_CRYPTO_LZ4HC=y
CONFIG_CRYPTO_LZ4KD=y
CONFIG_CRYPTO_ZSTD=y
CONFIG_F2FS_FS_COMPRESSION=y
CONFIG_F2FS_FS_LZ4=y
CONFIG_F2FS_FS_LZ4HC=y
CONFIG_F2FS_FS_ZSTD=y
CONFIG_KERNEL_LZ4=y
CONFIG_KSU_SUSFS=y
CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y
CONFIG_KSU_SUSFS_SUS_PATH=y
CONFIG_KSU_SUSFS_SUS_MOUNT=y
CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y
CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y
CONFIG_KSU_SUSFS_SUS_KSTAT=y
CONFIG_KSU_SUSFS_SUS_OVERLAYFS=n
CONFIG_KSU_SUSFS_TRY_UMOUNT=y
CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y
CONFIG_KSU_SUSFS_SPOOF_UNAME=y
CONFIG_KSU_SUSFS_ENABLE_LOG=y
CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y
CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y
CONFIG_KSU_SUSFS_OPEN_REDIRECT=y
EOF
    echo "GKI配置完成"
}

# 制作AnyKernel3包
make_anykernel3(){
 git clone https://github.com/Kernel-SU/AnyKernel3.git --depth=1
 rm -rf ./AnyKernel3/.git
 rm -rf ./AnyKernel3/push.sh
 cp kernel_workspace/kernel_platform/common/out/arch/arm64/boot/Image ./AnyKernel3/
}
# SerialID_Check() {
#     local input="$1"
#     local suffix="TG@qdykernel"
#     local full_hex prefix32

#     if [ -z "$input" ]; then
#         echo "错误：请先输入您的设备ID"
#         exit 1
#     fi

#     # 如果已经包含 patch，直接退出
#     if grep -q 'SOC_SN_CHECK' init/main.c; then
#         echo "main.c 已包含 patch, 跳过"
#         exit 0
#     fi

#     # 下载 serialid_check.c
#     curl -fsSL -o serialid_check.c "https://raw.githubusercontent.com/Hivensafe/Demo_kernel/main/.github/workflows/tools/serialid_check.c"

#     # 计算 sha256 并取前 32 位
#     full_hex=$(printf "%s" "${input}${suffix}" | sha256sum | awk '{print $1}')
#     prefix32="${full_hex:0:32}"

#     if ! echo "$prefix32" | grep -qE '^[0-9a-f]{32}$'; then
#         echo "错误：设备ID不合法: $prefix32"
#         exit 1
#     fi

#     # 替换源码里的 EXPECTED_ASCII32
#     sed -i "s/8f0c3a9b0e2d4f11a0b2c3d4e5f60718/${prefix32}/" serialid_check.c

#     # 自动插入到 main.c
#     local LINE
#     LINE=$(grep -n '^#include' init/main.c | tail -n 1 | cut -d: -f1)
#     head -n "$LINE" init/main.c > init/main.c.patched
#     cat serialid_check.c >> init/main.c.patched
#     tail -n +$((LINE+1)) init/main.c >> init/main.c.patched
#     mv init/main.c.patched init/main.c

#     echo "已自动插入 serialid_check.c 到 main.c (EXPECT32=${prefix32})"
# }

# 主程序
main() {
    # check_environment
    # check_remote_status

    case "$1" in
        setup_lz4)
            setup_lz4
            ;;
        setup_gki_config)
            setup_gki_config
            ;;
        make_anykernel3)
            make_anykernel3
            ;;
        # SerialID_Check)
        #     SerialID_Check "$2"
        #     ;;
        *)
            echo "用法: $0 [setup_lz4 | setup_gki_config <config> | make_anykernel3 | SerialID_Check <设备ID>]"
            exit 1
            ;;
    esac
}

main "$@"
