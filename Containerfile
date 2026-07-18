FROM quay.io/almalinuxorg/almalinux-bootc:10.2@sha256:585a7eaab4e56a11e58042a835c4d328a72d6248019f01ee7fc3746d66a6d113

ARG K0S_VERSION=v1.36.2+k0s.0

ARG TARGETARCH

COPY fs/ /

RUN <<EORUN
# Build script

set -xeuo pipefail

OS_VERSION=$(. /etc/os-release && echo $VERSION_ID)
OS_VERSION_MAJOR="${OS_VERSION%.*}"
K8S_VERSION_MINOR="${K0S_VERSION%.*.*}"

echo "■■■■■ Install repos ■■■■■"
dnf install -y "dnf-command(config-manager)"
dnf install -y epel-release
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-${OS_VERSION}-$(uname -m)/pgdg-redhat-repo-latest.noarch.rpm
dnf config-manager --add-repo https://pkgs.tailscale.com/stable/rhel/${OS_VERSION_MAJOR}/tailscale.repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${K8S_VERSION_MINOR}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${K8S_VERSION_MINOR}/rpm/repodata/repomd.xml.key
EOF

echo "■■■■■ Install packages ■■■■■"
dnf install -y \
    postgresql18-server \
    tailscale \
    wireguard-tools \
    cloud-init qemu-guest-agent \
    systemd-networkd \
    dracut-network dracut-sshd \
    ufw \
    zsh fish \
    tmux screen \
    neovim jq yq \
    rsync tcpdump wget git strace \
    htop plocate tree \
    btrfs-progs snapper \
    nut \
    smartmontools gdisk \
    cockpit cockpit-selinux cockpit-ostree cockpit-kdump cockpit-sosreport \
    cri-tools kubectl \
    toolbox \
    cowsay figlet lolcat \
    "https://github.com/derailed/k9s/releases/latest/download/k9s_linux_$TARGETARCH.rpm"

curl -L https://github.com/CyberShadow/btdu/releases/latest/download/btdu-static-$(uname -m) -o /usr/bin/btdu && chmod +x /usr/bin/btdu

echo "■■■■■ Install k0s ■■■■■"
curl -sSLf https://get.k0s.sh | K0S_VERSION=$K0S_VERSION sh

echo "■■■■■ DNF clean up ■■■■■"
dnf clean all
rm -rf /var/cache/* /var/log/* /var/lib/dnf

# Enable and disable systemd units
echo "■■■■■ Setup services ■■■■■"
systemctl enable dracut-sshd-copy-keys.path
systemctl mask bootc-fetch-apply-updates.timer # unsupervised updates not recommended with encryption layer
systemctl disable NetworkManager
systemctl enable systemd-networkd
ln -s ../cloud-init.target /usr/lib/systemd/system/default.target.wants

echo "■■■■■ Setup utilities ■■■■■"
# Set fish as default shell
usermod -s /usr/bin/fish root

echo "■■■■■ Setup readonly paths ■■■■■"
# Make some paths needed by k0s writable
ln -s /var/libexec/k0s /usr/libexec/k0s
ln -s /var/opt/cni /opt/cni
ln -s /var/local/lib/local-path-provisioner /opt/local-path-provisioner

echo "■■■■■ Setup initramfs ■■■■■"
# Create dummy dracut ssh host key to prevent dracut installation failing
touch /etc/ssh/dracut_ssh_host_ecdsa_key{,.pub}
touch /etc/dracut-sshd/authorized_keys

# Regenerate initramfs
kernel_version=$(cd /usr/lib/modules && echo *)
dracut -vf /usr/lib/modules/$kernel_version/initramfs.img $kernel_version

# Remove files required only for initramfs
rm -rf \
	/etc/dracut-sshd/	/etc/dracut.conf.d/* \
	/etc/systemd/system/sshd.service.d/*

echo "■■■■■ /var clean up ■■■■■"
# Remove unrequired file from /var
rm -rf \
    /var/lib/plocate/CACHEDIR.TAG \
    /var/lib/ufw/user*.rules \
    /var/lib/pgsql \
    /var/lib/selinux \
    /var/lib/cloud \
    /var/lib/dhcpcd

echo "■■■■■ Build complete ■■■■■"
EORUN

RUN bootc container lint --no-truncate
