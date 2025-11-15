FROM quay.io/fedora/fedora-bootc:42

ARG K0S_VERSION=v1.34.1+k0s.1

ARG TARGETARCH

COPY fs/ /

RUN <<EORUN
# Build script

set -e # Exit build if any subcommand fails

echo "■■■■■ Install packages ■■■■■"
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/F-$(rpm -E %fedora)-x86_64/pgdg-fedora-repo-latest.noarch.rpm
dnf install -y \
    postgresql18-server \
    tailscale \
    wireguard-tools \
    cloud-init qemu-guest-agent \
    systemd-networkd netplan \
    dracut-network dracut-sshd \
    ufw \
    zsh fish \
    tmux screen \
    neovim jq yq prename \
    rsync tcpdump wget \
    htop plocate tree \
    btrfs-progs snapper \
    cockpit cockpit-selinux cockpit-ostree cockpit-kdump cockpit-sosreport \
    cri-tools kubernetes1.33-client \
    toolbox \
    cowsay figlet lolcat \
    "https://github.com/derailed/k9s/releases/latest/download/k9s_linux_$TARGETARCH.rpm"
[[ $TARGETARCH == "amd64" ]] && curl -L https://github.com/CyberShadow/btdu/releases/latest/download/btdu-static-x86_64 -o /usr/bin/btdu && chmod +x /usr/bin/btdu

echo "■■■■■ Install packages from RPM fusion ■■■■■"
dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
dnf install -y \
    ffmpeg

echo "■■■■■ Install k0s ■■■■■"
curl -sSLf https://get.k0s.sh | K0S_VERSION=$K0S_VERSION sh

echo "■■■■■ DNF clean up ■■■■■"
dnf clean all
rm -rf /var/cache/* /var/log/* /var/lib/dnf

# Enable and disable systemd units
echo "■■■■■ Setup services ■■■■■"
systemctl enable dracut-sshd-copy-keys.path
systemctl disable bootc-fetch-apply-updates.timer
systemctl disable NetworkManager
systemctl enable systemd-networkd
systemctl enable ufw-init
ln -s ../cloud-init.target /usr/lib/systemd/system/default.target.wants

echo "■■■■■ Setup utilities ■■■■■"
# Set fish as default shell
usermod -s /usr/bin/fish root

echo "■■■■■ Setup readonly paths ■■■■■"
# Make some paths needed by k0s writable
ln -s /var/libexec/k0s /usr/libexec/k0s
ln -s /var/opt/cni /opt/cni
ln -s /var/local/lib/local-path-provisioner /opt/local-path-provisioner

echo "■■■■■ /var clean up ■■■■■"
# Remove unrequired file from /var
rm -rf \
    /var/lib/plocate/CACHEDIR.TAG \
    /var/lib/ufw/user*.rules \
    /var/lib/selinux

echo "■■■■■ Setup initramfs ■■■■■"
# Create dummy dracut ssh host key to prevent dracut installation failing
touch /etc/ssh/dracut_ssh_host_ecdsa_key{,.pub}
touch /etc/dracut-sshd/authorized_keys

# Regenerate initramfs
set -x
kernel_version=$(cd /usr/lib/modules && echo *)
dracut -vf /usr/lib/modules/$kernel_version/initramfs.img $kernel_version
set +x

# Remove files required only for initramfs
rm -rf \
	/etc/dracut-sshd/	/etc/dracut.conf.d/* \
	/etc/systemd/system/sshd.service.d/*

echo "■■■■■ Build complete ■■■■■"
EORUN

RUN bootc container lint --no-truncate
