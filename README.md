# Prepare Proxmox cloud
## Prepare Proxmox environment (host server)
- Do regular install
- Install some more useful tools
```bash
# apt install vim mlocate screen mc parted rsync htop iotop nmap tcpdump \
mtr-tiny net-tools openvswitch-switch
```
<hr>



# Prepare Cloud-Init template
**NOTE:** All examples are with CentOS-7. You can download Cloud-Init template or to create your own
Source: [https://pve.proxmox.com/wiki/Cloud-Init_Support#_preparing_cloud_init_templates](https://pve.proxmox.com/wiki/Cloud-Init_Support#_preparing_cloud_init_templates)

## Create Cloud-Init template from preinstalled image 
Preinstalled images location: http://cloud.centos.org/centos/7/images/

- Download selected image to Proxmox VE
```bash
# mkdir -p /data/ci && \
cd /data/ci && \
wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1809.qcow2
```
- Create new VM
```bash
# qm create 9000 --memory 512 --net0 virtio,bridge=vmbr0
```
- Import downloaded image to local VM HDD storage (depends on your proxmox implementation)
```bash
# qm importdisk 9000 CentOS-7-x86_64-GenericCloud-1809.qcow2 data-hdd
```
- Attach imported disk to VM
```bash
# qm set 9000 --scsihw virtio-scsi-pci --scsi0 data-hdd:9000/vm-9000-disk-1.raw
```
- Configure to boot from Cloud-Init disk (scsi0)
```bash
# qm set 9000 --boot c --bootdisk scsi0
```
- Configure serial console as external display
```bash
# qm set 9000 --serial0 socket --vga serial0
```
- Boot VM and wait until cloud-init do full OS update. It will sppedup next deployments
- Stop VM
- Convert VM to template
```bash
# qm template 9000
```

## Create Cloud-Init template manually
***<u>NOTE: Template will be prepared for testing purposes with disabled firewall and SELinux!</u>***

- Download latest CentOS-7 minimal .iso
- Upload .iso image to Proxmox VE
- Create CentOS-7 VM (RAM:1024MB, HDD:8GB, CPU:1-core-1-thread, LAN:1)
- Install CentOS-7 minimal
- Add "***centos***" user with password "***centos***"
```bash
# adduser centos
# passwd centos
```
- Generate RSA keys for ***root*** and ***centos***
```bash
# ssh-keygen -t rsa
```
- change color prompt for ***root*** and ***centos*** user
```bash
# cat > /root/.bashrc <<EOF
# .bashrc

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -la --color=auto'
alias mc='. /usr/share/mc/bin/mc-wrapper.sh'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

export 'PS1=\[\033[01;31m\][\u@\h \w ]\$ \[\033[00m\]'
EOF
```
```bash
# cat > /home/centos/.bashrc <<EOF
# .bashrc

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -la --color=auto'
alias mc='. /usr/share/mc/bin/mc-wrapper.sh'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

export 'PS1=\[\033[01;32m\][\u@\h \[\033[01;34m\]\w \[\033[01;32m\]]\$ \[\033[00m\]'
EOF
```
- Install EPEL repository
```bash
# yum install epel-release
```
- install additional packages
```bash
# yum install  net-tools rsync vim-enhanced nc mc wireshark tcpdump wget strace lynx links sysstat lsof deltarpm mlocate bash-completion nmap telnet screen iotop htop mtr traceroute ntpdate lshw ntp
```
- Disable SELinux
```bash
# sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```
- Enable multihostname support
```bash
# sed -i 's/multi on/multi off/g' -i /etc/host.conf
```
- Disable and remove NetworkManager and firewall
```bash
# for i in NetworkManager firewalld rhnsd; do systemctl mask $i; done
# for i in NetworkManager firewalld rhnsd; do systemctl stop $i; done
# yum remove $(rpm -qa | grep NetworkManager)
```
- Remove unneeded dependencies
```bash
# yum autoremove
```
- Do full upgrade
```bash
# yum upgrade
```
- Install Cloud-Init
```bash
# yum install cloud-init
```
- Stop VM
- Convert to template (right click -> "Convert to template")
- Remove CD-ROM
- Create Cloud-Init (Hardware -> Add -> CloudInit Drive -> IDE:0)
<hr>



# Prepare provisioning node (komander)
## Compile Proxmox provider

https://github.com/Telmate/terraform-provider-proxmox







# <u>Notes underline</u>

## Clone VM manually
```bash
# qm clone 9000 222 --name man-test
# qm set 222 --sshkey ~/.ssh/id_rsa.pub
# qm set 222 --net0 "virtio,bridge=vmbr0"
# qm set 222 --ipconfig0 ip=dhcp,gw=10.10.10.1
# qm start 222
```
### Revert template back to VM
(Example path and VMID 9001. Change with your own values)
- Remove template flag from VM configuration file
```bash
# sed -i '/template: 1/d' /etc/pve/qemu-server/9001.conf
```
-  Remove VMdisk attribute and change permissions
```bash
# chattr -i /data/hdd/images/9001/base-9001-disk-1.qcow2
# chmod 640 /data/hdd/images/9001/base-9001-disk-1.qcow2
```
## Set VM user/pass
```bash
# qm set 123 --ipconfig0 ip=x.x.x.x/yy,gw=x.x.x.x --cipassword="somepassword" --ciuser=root
```
## Test Proxmox API. User need to have access to all resources
```bash
# curl -k -d "username=root@pam&password=yourpassword" https://ipAddress:8006/api2/json/access/ticket
```
## set terraform debug. Available debug kevels:  TRACE, DEBUG, INFO, WARN or ERROR 
```bash
# export TF_LOG=DEBUG
# export TF_LOG_PATH=/tmp/log
```
```bash
# cat >> ~/.bash_profile <<EOF
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/log
EOF
```
## Login to qm console to execute commands against VM
```bash
# qm monitor VMID
```
## Add forwarding manually (example with VM ID 101)
```bash
# qm monitor 101
Entering Qemu Monitor for VM 101 - type 'help' for help
qm> netdev_add user,id=net1,hostfwd=tcp::22103-:22
qm> device_add virtio-net-pci,id=net1,netdev=net1,addr=0x13
```
