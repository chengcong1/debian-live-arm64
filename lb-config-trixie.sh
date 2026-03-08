#!/bin/bash

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


# 根据镜像源类型配置 apt 源
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

# 执行镜像配置
configure_mirror

LB_IMAGE_NAME="$MODE-$DISTRIBUTION-live" lb config \
    --mode $MODE \
	--architecture $ARCH \
	--debian-installer live \
    --debian-installer-gui true \
	--archive-areas 'main contrib non-free non-free-firmware' \
	--parent-archive-areas 'main contrib non-free non-free-firmware' \
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
    --bootappend-live "boot=live components quiet" \
	--binary-images iso-hybrid \
	--bootloaders grub-efi \
    --firmware-binary false \
    --firmware-chroot false \
	--apt-secure false \
	--updates true \
    # --cache-packages true \
    # --cache-stages bootstrap,chroot
	# --linux-packages "linux-image linux-dtb linux-headers" \
	# --linux-flavours "legacy-rk35xx" \

# package-lists 存放需要apt安装的包
# 添加桌面环境包 
cat > config/package-lists/desktop.list.chroot << EOF
xfce4
xfce4-goodies
xfce4-terminal
xfce4-power-manager
xfce4-screenshooter
lightdm
calamares
calamares-settings-debian
live-task-localisation
live-task-recommended

grub-efi-arm64
systemd-timesyncd
EOF

cat > config/package-lists/system.list.chroot << EOF
mesa-utils
firmware-misc-nonfree
nano
htop
gparted
locales
network-manager
network-manager-gnome
pulseaudio
alsa-utils
pavucontrol
bluetooth
wget
openssh-client
fonts-wqy-zenhei
EOF


# wget https://github.com/chengcong1/debian-live-arm64/releases/download/kernel_linux-7.0-rc2/linux-headers-7.0.0-rc2-moli-arm64.deb   -O config/package/linux-headers-arm64.deb
# wget https://github.com/chengcong1/debian-live-arm64/releases/download/kernel_linux-7.0-rc2/linux-image-7.0.0-rc2-moli-arm64.deb     -O config/package/linux-image-arm64.deb
# wget https://github.com/chengcong1/debian-live-arm64/releases/download/kernel_linux-7.0-rc2/linux-libc-dev_7.0.0-rc2-moli-arm64.deb  -O config/package/linux-libc-dev-arm64.deb

# 创建目录结构
mkdir -p config/includes.chroot/opt/custom-kernel

# 复制内核 deb 包到该目录
cp ../kernel/linux-image-*.deb config/includes.chroot/opt/custom-kernel/
cp ../kernel/linux-headers-*.deb config/includes.chroot/opt/custom-kernel/
cp ../kernel/linux-libc-dev-*.deb config/includes.chroot/opt/custom-kernel/

cp ../install-custom-kernel.hook.chroot config/hooks/live/
chmod +x config/hooks/chroot/install-custom-kernel.chroot

# 复制rtl8852be的固件到firmware目录
cp -r ../rtw89 config/includes.chroot/usr/lib/firmware/

