#!/bin/bash
# if [ "$GITHUB_ACTIONS" != "true" ]; then
#     echo "检测到非 GitHub Actions 环境，禁止本地执行！"
#     exit 1
# fi
setup_lz4(){
  git clone https://github.com/521141/Demo_kernel.git --depth=1 &>/dev/null
  rm -rf Demo_kernel/.git
  cp -r ./Demo_kernel/zram/lz4/* ./lib/lz4/
  cp -r ./Demo_kernel/zram/include/linux/* ./include/linux/
  cp ./Demo_kernel/zram/6.6/lz4_1.10.0.patch ./
  patch -p1 -F 3 --fuzz=5 < lz4_1.10.0.patch || true

  # 检查文件是否存在
  if [ -f "fs/f2fs/Makefile" ]; then
      # 检查是否包含指定行
      if ! grep -qF "f2fs-\$(CONFIG_F2FS_IOSTAT) += iostat.o" "fs/f2fs/Makefile"; then
          echo "f2fs-\$(CONFIG_F2FS_IOSTAT) += iostat.o" >> "fs/f2fs/Makefile"
          echo "已添加: f2fs-\$(CONFIG_F2FS_IOSTAT) += iostat.o"
      else
          echo "文件已经包含: f2fs-\$(CONFIG_F2FS_IOSTAT) += iostat.o"
      fi
  else
      echo "文件不存在: fs/f2fs/Makefile"
  fi
}

setup_device_info(){
 case "$1" in
    oneplus_ace5_pro)
      echo "REPO_MANIFEST=JiuGeFaCai_oneplus_ace5_pro_v" >> $GITHUB_ENV
      echo "DEVICES_NAME=oneplus_ace5_pro" >> $GITHUB_ENV
      ;;
    oneplus_13)
      echo "REPO_MANIFEST=JiuGeFaCai_oneplus_13_v" >> $GITHUB_ENV
      echo "DEVICES_NAME=oneplus_13" >> $GITHUB_ENV
      ;;
    oneplus_13t)
      echo "REPO_MANIFEST=oneplus_13t" >> $GITHUB_ENV
      echo "DEVICES_NAME=oneplus_13t" >> $GITHUB_ENV
      ;;
    oneplus_pad_2_pro)
      echo "REPO_MANIFEST=oneplus_pad_2_pro" >> $GITHUB_ENV
      echo "DEVICES_NAME=oneplus_pad_2_pro" >> $GITHUB_ENV
      ;;
    oneplus_ace5_ultra)
      echo "REPO_MANIFEST=oneplus_ace5_ultra" >> $GITHUB_ENV
      echo "DEVICES_NAME=oneplus_ace5_ultra" >> $GITHUB_ENV
      ;;
    realme_GT7pro)
      echo "REPO_MANIFEST=realme_GT7pro" >> $GITHUB_ENV
      echo "DEVICES_NAME=realme_GT7pro" >> $GITHUB_ENV
      ;;
    realme_GT7pro_Speed)
      echo "REPO_MANIFEST=realme_GT7pro_Speed" >> $GITHUB_ENV
      echo "DEVICES_NAME=realme_GT7pro_Speed" >> $GITHUB_ENV
      ;;
  esac
}

setup_gki_config(){
  echo "CONFIG_KSU=y" >> ./common/arch/arm64/configs/gki_defconfig
  # Add VFS configuration settings
  echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_MANUAL_HOOK=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KPM=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_CRYPTO_LZ4=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_CRYPTO_LZ4HC=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_CRYPTO_LZ4KD=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_CRYPTO_ZSTD=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_F2FS_FS_COMPRESSION=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_F2FS_FS_LZ4=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_F2FS_FS_LZ4HC=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_F2FS_FS_ZSTD=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KERNEL_LZ4=y" >> ./common/arch/arm64/configs/gki_defconfig
  # Add SUSFS configuration settings
  echo "CONFIG_KSU_SUSFS=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=n" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" >> ./common/arch/arm64/configs/gki_defconfig
  echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./common/arch/arm64/configs/gki_defconfig
  # FQ_CODEL
  # echo "CONFIG_NET_SCH_FQ_CODEL=y" >> ./common/arch/arm64/configs/gki_defconfig
  # echo "CONFIG_NET_SCH_FQ=y" >> ./common/arch/arm64/configs/gki_defconfig
  # echo "CONFIG_NET_SCH_SFQ=y" >> ./common/arch/arm64/configs/gki_defconfig
  # echo "CONFIG_NET_SCH_HTB=y" >> ./common/arch/arm64/configs/gki_defconfig
  # echo "CONFIG_NET_SCH_TBF=y" >> ./common/arch/arm64/configs/gki_defconfig
  # echo "CONFIG_NET_SCH_SFB=y" >> ./common/arch/arm64/configs/gki_defconfig
  # echo "CONFIG_NET_SCH_RED=y" >> ./common/arch/arm64/configs/gki_defconfig
  # echo "CONFIG_NET_SCH_INGRESS=y" >> ./common/arch/arm64/configs/gki_defconfig
  # echo "CONFIG_DEFAULT_FQ_CODEL=y" >> ./common/arch/arm64/configs/gki_defconfig
  # echo 'CONFIG_DEFAULT_NET_SCH="fq_codel"' >> ./common/arch/arm64/configs/gki_defconfig
}



make_anykernel3(){
 git clone https://github.com/Kernel-SU/AnyKernel3.git --depth=1
 rm -rf ./AnyKernel3/.git
 rm -rf ./AnyKernel3/push.sh
 cp kernel_workspace/kernel_platform/common/out/arch/arm64/boot/Image ./AnyKernel3/
}
case "$1" in
  setup_lz4)
    setup_lz4
    ;;
  setup_device_info)
    setup_device_info "$2"
    ;;
  setup_gki_config)
    setup_gki_config "$2"
    ;;
  make_anykernel3)
    make_anykernel3
    ;;
  *)
    echo "用法: $0 [setup_lz4|setup_device_info|setup_gki_config|make_anykernel3]"
    exit 1
    ;;
esac
