#!/bin/sh

vms=""

# KVM / QEMU (libvirt)
if command -v virsh >/dev/null 2>&1; then
    kvm=$(virsh -c qemu:///system list --name --state-running 2>/dev/null |
        awk 'NF {printf "%s%s (KVM/QEMU)", sep, $0; sep=", "}')
    [ -n "$kvm" ] && vms="$kvm"
fi

# VirtualBox
if command -v VBoxManage >/dev/null 2>&1; then
    vbox=$(VBoxManage list runningvms 2>/dev/null |
        sed -n 's/^"\([^"]*\)".*$/\1 (VirtualBox)/p' |
        paste -sd ', ' -)

    if [ -n "$vbox" ]; then
        [ -n "$vms" ] && vms="$vms, "
        vms="$vms$vbox"
    fi
fi

# VMware
if command -v vmrun >/dev/null 2>&1; then
    vmware=$(vmrun list 2>/dev/null |
        tail -n +2 |
        sed '/^[[:space:]]*$/d; s#^.*/##; s/\.vmx$//; s/$/ (VMware)/' |
        paste -sd ', ' -)

    if [ -n "$vmware" ]; then
        [ -n "$vms" ] && vms="$vms, "
        vms="$vms$vmware"
    fi
fi

[ -n "$vms" ] && printf '%s\n' "$vms"
