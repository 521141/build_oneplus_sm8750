#!/bin/bash
set -euo pipefail

# 全局变量
readonly GITHUB_ENV=${GITHUB_ENV:-".env"}
readonly REPO_URL="https://raw.githubusercontent.com/Hivensafe/cloud_kernel_enable/main"
readonly DEMO_REPO="https://github.com/Hivensafe/Demo_kernel.git"
readonly ANYKERNEL_REPO="https://github.com/Kernel-SU/AnyKernel3.git"
readonly TG_CHANNEL="https://t.me/qdykernel"

# # 检查环境
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

# 制作AnyKernel3包
make_anykernel3() {
    local kernel_image="kernel_workspace/common/out/arch/arm64/boot/Image"

    echo "正在制作AnyKernel3包..."

    if [ ! -f "$kernel_image" ]; then
        echo "错误：找不到内核镜像文件 ${kernel_image}"
        exit 1
    fi

    if ! git clone "${ANYKERNEL_REPO}" --depth=1; then
        echo "错误：克隆AnyKernel3仓库失败"
        exit 1
    fi

    rm -rf ./AnyKernel3/.git ./AnyKernel3/push.sh

    if ! cp "$kernel_image" ./AnyKernel3/; then
        echo "错误：复制内核镜像失败"
        exit 1
    fi
    echo "AnyKernel3包制作完成"
}

# 主程序
main() {
    # check_environment
    # check_remote_status

    case "$1" in
        make_anykernel3)
            make_anykernel3
            ;;
        *)
            echo "错误，未知参数 $1"
            exit 1
            ;;
    esac
}

main "$@"
