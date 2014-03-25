#!/bin/bash
HOSTNAME="vagrant.nzwsch.net"
Zone="Asia"
SubZone="Tokyo"

# Prepare the storage drive
fdisk /dev/sda <<EOF
n
p
1

+38G
n
e
2


n
l


p
w
EOF

# Create filesystems
mkfs.ext4 /dev/sda1
mkswap /dev/sda5
swapon /dev/sda5

# Mount the partitions
mount /dev/sda1 /mnt

# Select a mirror
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#//' /etc/pacman.d/mirrorlist.backup
echo "sorting mirror..."
rankmirrors /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
pacman-db-upgrade

# Install the base system
pacman -Syy
pacstrap /mnt base base-devel openssh grub virtualbox-guest-utils ruby

# Generate an fstab
genfstab -L -p /mnt >> /mnt/etc/fstab

# Chroot and configure the base system
arch-chroot /mnt <<EOF
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
locale-gen

echo LANG=en_US.UTF-8 > /etc/locale.conf

ln -s /usr/share/zoneinfo/$Zone/$SubZone /etc/localtime

echo $HOSTNAME > /etc/hostname

systemctl enable sshd

touch /etc/udev/rules.d/80-net-setup-link.rules
ln -s /usr/lib/systemd/system/dhcpcd@.service /etc/systemd/system/multi-user.target.wants/dhcpcd@eth0.service

echo "root:vagrant" | chpasswd

grub-install --target=i386-pc --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
sed -i 's/timeout=5/timeout=0/' /boot/grub/grub.cfg

gem install chef --no-user-install --no-ri --no-rdoc

useradd -m -G vboxsf vagrant
echo "vagrant:vagrant" | chpasswd

echo vboxguest >> /etc/modules-load.d/virtualbox.conf
echo vboxsf    >> /etc/modules-load.d/virtualbox.conf
echo vboxvideo >> /etc/modules-load.d/virtualbox.conf

echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_vagrant
echo 'vagrant ALL=(ALL) NOPASSWD: ALL'     >> /etc/sudoers.d/10_vagrant
chmod 0440 /etc/sudoers.d/10_vagrant

su - vagrant
mkdir ~/.ssh
curl -L https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub > ~/.ssh/authorized_keys
exit
EOF

# Unmount the partitions and reboot
umount -R /mnt
swapoff /dev/sda5
reboot
