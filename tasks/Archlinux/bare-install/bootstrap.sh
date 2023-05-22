#!/usr/bin/env bash

# Customization section
UCODE_TYPE=amd-ucode
SWAP_PATH=/mnt/home/system
SWAP_SIZE=16384        # In mb
DISK_DEVICE=/dev/nvme0n1
MAKE_PARTITIONS=0

if [[ $MAKE_PARTITIONS == 1 ]]; then
  # Remove all previous partitions
  parted $DISK_DEVICE mklabel gpt

  # Create partitions (This is for 1TB hard drive)
  parted $DISK_DEVICE mkpart boot fat32 1MiB 1024MiB
  parted $DISK_DEVICE set 1 esp on
  parted $DISK_DEVICE mkpart root ext4 1024MiB 82944MiB
  parted $DISK_DEVICE mkpart home ext4 82944MiB 100%

  mkfs.fvat -F 32 "${DISK_DEVICE}p1"
  mkfs.ext4 "${DISK_DEVICE}p2"
  mkfs.ext4 "${DISK_DEVICE}p3"
fi

echo "*** Mounting disks ***"
mount "${DISK_DEVICE}p2" /mnt
mkdir -p /mnt/boot/efi /mnt/home
mount "${DISK_DEVICE}p1" /mnt/boot/efi
mount "${DISK_DEVICE}p3" /mnt/home

echo "*** Creating and mounting swapfile ***"
mkdir $SWAP_PATH
dd if=/dev/zero of=$SWAP_PATH/swapfile bs=1M count=$SWAP_SIZE status=progress
chmod 600 $SWAP_PATH/swapfile
mkswap $SWAP_PATH/swapfile
swapon $SWAP_PATH/swapfile
unset $SWAP_PATH
unset $SWAP_SIZE

echo "*** Setting time ***"
timedatectl set-ntp true

echo "*** Installing base system ***"
pacstrap /mnt \
    base \
    linux-zen linux-firmware linux-headers dkms $UCODE_TYPE \
    sudo networkmanager grub efibootmgr \
    git ansible 

unset $UCODE_TYPE

echo "*** Generating fstabs ***"
genfstab -U /mnt >> /mnt/etc/fstab

echo "*** CHROOT ***"
arch-chroot /mnt ./base-config.sh

