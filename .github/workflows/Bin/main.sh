#!/bin/bash
set -euo pipefail

# 全局变量
# readonly GITHUB_ENV=${GITHUB_ENV:-".env"}
# readonly REPO_URL="https://raw.githubusercontent.com/Hivensafe/cloud_kernel_enable/main"
readonly DEMO_REPO="https://github.com/521141/Demo_kernel.git"
readonly ANYKERNEL_REPO="https://github.com/showdo/AnyKernel3.git"

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

#     # 获取启用标志并去掉 BOM 和所有空白字符
#     flag=$(curl -fsSL "${REPO_URL}/enable.txt" | sed -e '1s/^\xEF\xBB\xBF//' | tr -d '[:space:]') || {
#         echo "错误：无法获取启用标志"
#         exit 1
#     }

#     # 获取版本信息并去掉 BOM 和所有空白字符
#     version=$(curl -fsSL "${REPO_URL}/main_version.txt" | sed -e '1s/^\xEF\xBB\xBF//' | tr -d '[:space:]') || {
#         echo "错误：无法获取版本信息"
#         exit 1
#     }

#     # 调试输出：检查 flag 和 version 的值
#     echo "debug = '$flag'"
#     echo "debug: version = '$version'"

#     # 检查启用标志是否为 "on"
#     if [ "$flag" != "on" ]; then
#         echo "错误：服务未启用，请联系作者"
#         echo "TG频道：${TG_CHANNEL}"
#         exit 1
#     fi

#     # 检查版本是否为 "10006"
#     if [ "$version" != "10006" ]; then
#         echo "错误：分支已过期 (最新: ${version}，当前: 10006)"
#         echo "请同步上游更新"
#         echo "TG频道：${TG_CHANNEL}"
#         exit 1
#     fi
# }



# 设置LZ4配置
setup_lz4() {
    echo "正在设置LZ4配置..."
    # 克隆仓库
    if [ ! -d "./Demo_kernel" ]; then
        if ! git clone "${DEMO_REPO}" --depth=1 &>/dev/null; then
            exit 1
        fi
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

    # 定义需要设置的配置项数组
    local config_items=(
        "CONFIG_KSU=y"
        # "CONFIG_KSU_MANUAL_HOOK=y"
        "CONFIG_KSU_TRACEPOINT_HOOK=y"
        "CONFIG_KPM=y"
        "CONFIG_CRYPTO_LZ4=y"
        "CONFIG_CRYPTO_LZ4HC=y"
        "CONFIG_CRYPTO_LZ4KD=y"
        "CONFIG_CRYPTO_ZSTD=y"
        "CONFIG_F2FS_FS_COMPRESSION=y"
        "CONFIG_F2FS_FS_LZ4=y"
        "CONFIG_F2FS_FS_LZ4HC=y"
        "CONFIG_F2FS_FS_ZSTD=y"
        "CONFIG_KERNEL_LZ4=y"
        "CONFIG_KSU_SUSFS=y"
        "CONFIG_KSU_SUSFS_SUS_SU=n"
        "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y"
        "CONFIG_KSU_SUSFS_SUS_PATH=y"
        "CONFIG_KSU_SUSFS_SUS_MOUNT=y"
        "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y"
        "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y"
        "CONFIG_KSU_SUSFS_SUS_KSTAT=y"
        "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=n"
        "CONFIG_KSU_SUSFS_TRY_UMOUNT=y"
        "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y"
        "CONFIG_KSU_SUSFS_SPOOF_UNAME=y"
        "CONFIG_KSU_SUSFS_ENABLE_LOG=y"
        "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y"
        "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y"
        "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y"
        "CONFIG_TMPFS_XATTR=y"
        "CONFIG_TMPFS=y"
    )

    # 遍历每个配置项
    for config in "${config_items[@]}"; do
        # 提取配置项的名称（例如从 "CONFIG_KSU=y" 中提取 "CONFIG_KSU"）
        local config_name="${config%%=*}"  # 使用 %% 从右边删除第一个 = 及其右边的所有内容

        # 检查配置项是否已存在（忽略注释行）
        if grep -qE "^(# )?$config_name=" "$defconfig"; then
            # 如果存在，则替换该行
            # 注意：sed 中的 & 代表匹配到的整个内容
            # 这里使用 \1 捕获组来保留可能的注释前缀（# 或 # ）
            sed -i "s/^\(# \)\?$config_name=.*/$config/" "$defconfig"
            echo "已更新: $config"
        else
            # 如果不存在，则追加到文件末尾
            echo "$config" >> "$defconfig"
            echo "已添加: $config"
        fi
    done

    echo "GKI配置完成"
}

# 制作AnyKernel3包
make_anykernel3() {
 git clone https://github.com/Kernel-SU/AnyKernel3.git --depth=1
 rm -rf ./AnyKernel3/.git
 rm -rf ./AnyKernel3/push.sh
 cp kernel_workspace/kernel_platform/common/out/arch/arm64/boot/Image ./AnyKernel3/
    echo "AnyKernel3包制作完成"
}

# 设置Baseband Guard
baseband_guard() {
    set -e
    # 下载脚本
    if ! curl -sSL https://raw.githubusercontent.com/vc-teahouse/Baseband-guard/main/setup.sh -o setup.sh; then
        echo "错误：下载 setup.sh 失败"
        return 1
    fi
    
    # 检查文件是否存在且有执行权限
    if [ ! -f "setup.sh" ]; then
        echo "错误：setup.sh 文件不存在"
        return 1
    fi
    
    chmod +x setup.sh
    
    # 检查目标目录是否存在
    if [ ! -d "./arch/arm64/configs" ]; then
        echo "错误：目标目录 ./arch/arm64/configs 不存在"
        echo "当前目录内容:"
        ls -la
        return 1
    fi
    
    # 执行脚本
    if ! bash setup.sh; then
        echo "错误：执行 setup.sh 失败"
        return 1
    fi
    
    # 追加配置
    echo >> ./arch/arm64/configs/gki_defconfig
    echo 'CONFIG_BBG=y' >> ./arch/arm64/configs/gki_defconfig
    echo 'CONFIG_LSM="landlock,lockdown,yama,loadpin,safesetid,selinux,smack,tomoyo,apparmor,bpf,baseband_guard"' >> ./arch/arm64/configs/gki_defconfig
    echo "Baseband Guard 配置完成"
}

# # 序列号检查
# SerialID_Check() {
#     local input="$1"
#     local suffix="TG@qdykernel"
#     local full_hex prefix32

#     # 输入验证：检查设备ID是否为空
#     if [ -z "$input" ]; then
#         exit 1
#     fi

#     # 检查 main.c 是否已经包含 patch
#     if grep -q 'SOC_SN_CHECK' init/main.c; then
#         exit 0
#     fi

#     # 如果 Demo_kernel 文件夹不存在，才克隆仓库
#     if [ ! -d "./Demo_kernel" ]; then
#         if ! git clone "${DEMO_REPO}" --depth=1 &>/dev/null; then
#             exit 1
#         fi
#     fi

#     # 从 Demo_kernel 中复制 serialid_check.c 文件
#     if ! cp "./Demo_kernel/.github/workflows/tools/serialid_check.c" ./; then
#         exit 1
#     fi

#     # 计算 sha256 并取前 32 位
#     full_hex=$(printf "%s" "${input}${suffix}" | sha256sum | awk '{print $1}')
#     prefix32="${full_hex:0:32}"

#     # 校验前32位合法性
#     if ! echo "$prefix32" | grep -qE '^[0-9a-f]{32}$'; then
#         exit 1
#     fi

#     # 替换 serialid_check.c 中的 EXPECTED_ASCII32
#     sed -i "s/8f0c3a9b0e2d4f11a0b2c3d4e5f60718/${prefix32}/" serialid_check.c
    

#     # 查找并插入 serialid_check.c 到 main.c
#     local LINE
#     LINE=$(grep -n '^#include' init/main.c | tail -n 1 | cut -d: -f1)
#     if [ -z "$LINE" ]; then
#         exit 1
#     fi

#     # 将 serialid_check.c 插入到 main.c
#     head -n "$LINE" init/main.c > init/main.c.patched
#     cat serialid_check.c >> init/main.c.patched
#     tail -n +$((LINE+1)) init/main.c >> init/main.c.patched
#     mv init/main.c.patched init/main.c
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
        baseband_guard)
            baseband_guard
            ;;
        *)
            echo "错误，未知参数 $1"
            exit 1
            ;;
    esac
}

main "$@"
