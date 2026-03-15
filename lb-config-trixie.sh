#!/bin/bash

echo $PWD
# mkdir -p live-build&& cd live-build
echo $PWD
# 默认配置
MODE="debian"
DISTRIBUTION="trixie"
MIRROR_TYPE="official"
ARCH="arm64"


# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --distribution)
            DISTRIBUTION="$2"
            shift 2
            ;;
        --mirror)
            MIRROR_TYPE="$2"
            shift 2
            ;;
        --arch)
            ARCH="$2"
            shift 2 # skpping 2 arguments
            ;;
        --mode)
		MODE="$2"
            shift 2
            ;;

        --help)
            echo "用法：$0 [--distribution <版本>] [--mirror <镜像源>] [--arch <架构>] [--help] "
            echo "发行版：bookworm, trixie, forky"
			echo "镜像源选项：aliyun, tsinghua, official"
			echo "架构选择：arm64"
            exit 0
            ;;
        *)
            echo "未知参数：$1"
            exit 1
            ;;
    esac
done

configure_mirror() {
    case $MIRROR_TYPE in
        aliyun)
            MIRROR_BASE="https://mirrors.aliyun.com/debian/"
            MIRROR_SECURITY="https://mirrors.aliyun.com/debian-security/"
            ;;
        tsinghua)
            MIRROR_BASE="https://mirrors.tuna.tsinghua.edu.cn/debian/"
            MIRROR_SECURITY="https://mirrors.tuna.tsinghua.edu.cn/debian-security/"
            ;;
        official|*)
            MIRROR_BASE="http://ftp.debian.org/debian/"
            MIRROR_SECURITY="http://security.debian.org/debian-security/"
            ;;
    esac
}

# execute
configure_mirror

LB_IMAGE_NAME="$MODE-$DISTRIBUTION-live" lb config \
    --mode $MODE \
    --architecture $ARCH \
    --archive-areas "main contrib non-free non-free-firmware" \
    --parent-archive-areas "main contrib non-free non-free-firmware" \
    --debian-installer-distribution $DISTRIBUTION \
    --distribution $DISTRIBUTION \
    --distribution-chroot $DISTRIBUTION \
    --distribution-binary $DISTRIBUTION\
    --keyring-packages "debian-archive-keyring ca-certificates fontconfig-config initramfs-tools" \
    --parent-mirror-bootstrap $MIRROR_BASE \
    --parent-mirror-chroot $MIRROR_BASE \
    --parent-mirror-chroot-security $MIRROR_SECURITY \
    --parent-mirror-binary $MIRROR_BASE \
    --parent-mirror-binary-security $MIRROR_SECURITY \
    --parent-mirror-debian-installer $MIRROR_BASE \
    --mirror-bootstrap $MIRROR_BASE \
    --mirror-chroot $MIRROR_BASE \
    --mirror-chroot-security $MIRROR_SECURITY \
    --mirror-binary $MIRROR_BASE \
    --mirror-binary-security $MIRROR_BASE \
    --mirror-debian-installer $MIRROR_BASE \
    --bootappend-live "boot=live components quiet locales=zh_CN.UTF-8" \
    --binary-images iso-hybrid \
    --bootloaders grub-efi \
    --firmware-binary false \
    --firmware-chroot false \
    --apt-secure false \
    --updates true \
    --apt-recommends false
    # --debian-installer false
    # --cache-packages true \
    # --cache-stages bootstrap,chroot
    # --debian-installer live \
    # --debian-installer-gui true \
    # --linux-packages "linux-image linux-dtb linux-headers" \
    # --linux-flavours "legacy-rk35xx" \
    # --apt-recommends false 不安装推荐的包，减少ios镜像大小，不能超过2GB

# persistence 持久化
# package-lists need to apt install packages in chroot
cp addpackage-custom.list.chroot config/package-lists/
cp addpackage-desktop.list.chroot config/package-lists/
# add other live packages 
cat > config/package-lists/livepkg.list.chroot << EOF
grub-efi-arm64
calamares-settings-debian
live-task-localisation
live-task-recommended
systemd-timesyncd

#live-boot
#live-config
#live-config-systemd
#systemd-sysv

live-tools
#live-config
#live-config-systemd
#live-boot
live-boot-initramfs-tools
user-setup
# 推荐依赖
#dbus
#debian-installer-launcher
#eject
#perl
#procps
#rsync
#uuid-runtime
#user-setup
#keyboard-configuration
#initramfs-tool
#udev
#dkms
EOF
# 减少体积
cat > config/hooks/live/0091-cleanup-packages.hook.chroot << EOF
#!/bin/bash
# 清理APT缓存
apt-get clean
# 删除文档和本地化文件（如果空间极度敏感）
# find /usr/share/doc -type f ! -name copyright -delete
# find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en' ! -name 'en_US' ! -name 'zh_CN' | xargs rm -rf
# find /usr/share/man -type f -delete
EOF
chmod +x config/hooks/live/0091-cleanup-packages.hook.chroot

# copy custom kernel in config/packages.chroot/
# no apt packages in config/packages.chroot/ auto install
cp ../kernel/*.deb config/packages.chroot/
# mkdir -p config/includes.chroot/opt/
# cp ../kernel/*.deb config/includes.chroot/opt/
# hooks remove-default-kernel
cp ../0090-remove-default-kernel.hook.chroot config/hooks/live/
chmod +x config/hooks/live/0090-remove-default-kernel.hook.chroot

# 复制rtl8852be的固件到firmware目录
mkdir -p config/includes.chroot/usr/lib/firmware
cp -r ../rtw89 config/includes.chroot/usr/lib/firmware/
# 如果内核包名还是版本是以-arm64结尾的，那么下面两行代码可以删除
mkdir -p config/bootloaders/grub-pc
cp ../grub.cfg config/bootloaders/grub-pc/
# mkdir -p config/includes.chroot/opt/
# cp ../kernel/*.deb config/includes.chroot/opt/
# sudo lb build