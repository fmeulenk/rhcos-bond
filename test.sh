#!/usr/bin/env bash

# See OpenShift 4 UPI Installation on KVM/Libvirt
# https://mojo.redhat.com/people/knaeem/blog/2019/08/17/openshift-4-upi-installation-on-kvmlibvirt

# Create password for user core and reuse an old key
# echo test | openssl passwd -stdin -6
# Add that and change ssh-key in test.ign

# Download images
# wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.2/4.2.0/rhcos-4.2.0-x86_64-metal-bios.raw.gz
# mkdir rhcos-install
# wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.2/4.2.0/rhcos-4.2.0-x86_64-installer-kernel -O rhcos-install/vmlinuz
# wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.2/4.2.0/rhcos-4.2.0-x86_64-installer-initramfs.img -O rhcos-install/initramfs.img
#
# cat <<EOF > rhcos-install/.treeinfo
# [general]
# arch = x86_64
# family = Red Hat CoreOS
# platforms = x86_64
# version = 4.2.0
# [images-x86_64]
# initrd = initramfs.img
# kernel = vmlinuz
# EOF

# Create a new isolated network called "iso1"

VIR_NET="default"
VIR_NET2="iso1"

HOST_NET=$(ip -4 a s $(virsh net-info $VIR_NET | awk '/Bridge:/{print $2}') | awk '/inet /{print $2}')
HOST_IP=$(echo $HOST_NET | cut -d '/' -f1)

WEB_PORT="1234"
# FME Hacked tmux in instead of screen
tmux new -ds webserver bash -c "python3 -m http.server ${WEB_PORT}"

# Will fire a error if running for the second time
firewall-cmd --add-source=${HOST_NET}
firewall-cmd --add-port=${WEB_PORT}/tcp

# Start the VM
virt-install --name rhcos \
  --disk rhcos,size=20 --ram 4000 --cpu host --vcpus 2 \
  --os-type linux --os-variant rhel7.0 \
  --network network=$VIR_NET \
  --network network=$VIR_NET \
  --network network=$VIR_NET2 \
  --network network=$VIR_NET2 \
  --noautoconsole \
  --noreboot \
  --location rhcos-install/ \
  --extra-args "nomodeset rd.neednet=1 coreos.inst=yes coreos.inst.install_dev=vda coreos.inst.image_url=http://${HOST_IP}:${WEB_PORT}/rhcos-4.2.0-x86_64-metal-bios.raw.gz coreos.inst.ignition_url=http://${HOST_IP}:${WEB_PORT}/test.ign"
