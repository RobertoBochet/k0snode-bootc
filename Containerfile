FROM quay.io/fedora/fedora-bootc:42

ARG K0S_VERSION=v1.33.3+k0s.0
ARG POSTGRESQL_SERVER_VERSION=16.9
ARG TAILSCALE_VERSION=1.84.1
ARG WIREGUARD_TOOLS_VERSION=1.0.20210914

ARG TARGETARCH

ARG SSH_AUTHORIZED_KEYS
ARG SSH_AUTHORIZED_KEYS_CHECK_SKIP=false

COPY fs/ /

RUN <<EORUN
# Build script

set -e # Exit build if any subcommand fails

echo "■■■■■ Setup ssh keys ■■■■■"
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
  mkdir /usr/ssh
  echo "$SSH_AUTHORIZED_KEYS" > /usr/ssh/root.keys
  echo "$SSH_AUTHORIZED_KEYS" > /etc/dracut-sshd/authorized_keys
  echo "authorized keys:"
  ssh-keygen -lf /usr/ssh/root.keys || (echo "Invalid keys" && exit 1)
elif [ "$SSH_AUTHORIZED_KEYS_CHECK_SKIP" == false ]; then
  echo "Error: You do not provide any ssh keys with the build argument 'SSH_AUTHORIZED_KEYS'"
  echo "If you want to skip this check provide the building argument 'SSH_AUTHORIZED_KEYS_CHECK_SKIP=true'"
  exit 1
fi

echo "■■■■■ Setup firstboot service ■■■■■"
mkdir /etc/firstboot.d
systemctl enable firstboot

echo "■■■■■ Install packages ■■■■■"
dnf install -y \
    postgresql-server-$POSTGRESQL_SERVER_VERSION \
    tailscale-$TAILSCALE_VERSION \
    wireguard-tools-$WIREGUARD_TOOLS_VERSION \
    "https://github.com/derailed/k9s/releases/latest/download/k9s_linux_$TARGETARCH.rpm" \
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
    cowsay figlet lolcat
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
systemctl disable NetworkManager
systemctl enable systemd-networkd
systemctl enable ufw-init

echo "■■■■■ Setup utilities ■■■■■"
# Set fish as default shell
usermod -s /usr/bin/fish root
# Set global environment variables
echo "KUBECONFIG=/var/lib/k0s/pki/admin.conf" >> /etc/environment
echo "EDITOR=nvim" >> /etc/environment

echo "■■■■■ Setup readonly paths ■■■■■"
# Make some paths needed by k0s writable
ln -s /var/libexec/k0s /usr/libexec/k0s
ln -s /var/opt/cni /opt/cni
ln -s /var/local/lib/local-path-provisioner /opt/local-path-provisioner

echo "■■■■■ /var clean up ■■■■■"
# Remove unrequired file from /var
rm -f \
    /var/lib/plocate/CACHEDIR.TAG \
    /var/lib/ufw/user*.rules

echo "■■■■■ Setup initramfs ■■■■■"
# Create dummy dracut ssh host key to prevent dracut installation failing
touch /etc/ssh/dracut_ssh_host_ecdsa_key{,.pub}

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
