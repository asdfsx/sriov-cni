   * [SR-IOV CNI plugin](#sr-iov-cni-plugin)
      * [Build](#build)
      * [Enable SR-IOV](#enable-sr-iov)
      * [Configuration reference](#configuration-reference)
         * [Main parameters](#main-parameters)
         * [Using DPDK drivers:](#using-dpdk-drivers)
         * [DPDK parameters](#dpdk-parameters)
      * [Usage](#usage)
         * [Configuration with IPAM:](#configuration-with-ipam)
         * [Configuration with DPDK:](#configuration-with-dpdk)
      * [Contacts](#contacts)

# SR-IOV CNI plugin
This repository contains the sriov CNI plugin that allows DPDK driver binding as well as the orginal featuers of [sriov-cni](https://github.com/hustcat/sriov-cni). To learn about CNI please visit [containernetworking/cni](https://github.com/containernetworking/cni).

NIC with [SR-IOV](http://blog.scottlowe.org/2009/12/02/what-is-sr-iov/) capabilities works by introducing the idea of physical functions (PFs) and virtual functions (VFs). 

PF is used by host. Each VFs can be treated as a separate physical NIC and assigned to one container, and configured with separate MAC, VLAN and IP, etc.

## Build

This plugin requires Go 1.5+ to build.

Go 1.5 users will need to set `GO15VENDOREXPERIMENT=1` to get vendored dependencies. This flag is set by default in 1.6.

```
#./build
```

## Build image

1. Install golang

2. Install qemu
   ```bash
   sudo apt-get install qemu-kvm qemu virt-manager virt-viewer libvirt-bin
   ```
   
   To support cross platform, the building scripts need to install qemu.
   
3. Enable docker experiment
   
   To enable experimental features, start the Docker daemon with the `--experimental` flag or enable the daemon flag in the /etc/docker/daemon.json configuration file:
   ```
   {
       "experimental": true
   }
   ```
   
   You can check to see if experimental features are enabled on a running daemon using the following command:
   
   ```
   $ docker version -f '{{.Server.Experimental}}'
   true
   ```
   
   When the building script calling `docker`, it add `--platform` parameter.
   If `experimental` is not enabled, it will cause the following problem
   
   > "--platform" is only supported on a Docker daemon with experimental features enabled 
   
4. Build images
   ```bash
   $ git clone http://github.com/mellanox/sriov-cni $GOPATH/src/github.com/mellanox/sriov-cni/
   $ cd $GOPATH/src/github.com/mellanox/sriov-cni/images
   $ ARCH=amd64 VERSION=v1.3.0 ./build_docker.sh manifest
   $ docker push ......
   ```
   
NOTE:
1. The new image should work with multus-cni
2. Since it's work with multus, so don't need copy `10-sriov-cni.conf` to host
3. Scripts in `k8s-installer` is useless
4. To support old deploy scripts, copy `k8s-installer` to `/installer` inside image
5. The `/installer` will be removed in the future  
 

Upon successful build the plugin binary will be available in `bin/sriov`. 

## Enable SR-IOV

Given Intel ixgbe NIC on CentOS, Fedora or RHEL:

```
# vi /etc/modprobe.conf
options ixgbe max_vfs=8,8
```

## Configuration reference
### Main parameters
* `name` (string, required): the name of the network
* `type` (string, required): "sriov"
* `if0` (string, optional): name of the PF, if not provided then `pfNetdevices` is required
* `if0name` (string, optional): interface name in the Container
* `pfNetdevices` (list, optional) PFs list, if not provided then `if0` is required
* `l2enable` (boolean, optional): if `true` then add VF as L2 mode only, IPAM will not be executed
* `vlan` (int, optional): VLAN ID to assign for the VF
* `ipam` (dictionary, optional): IPAM configuration to be used for this network.
* `dpdk` (dictionary, optional): DPDK configuration

### Using DPDK drivers:
If this plugin is use to bind a VF to dpdk driver then the IPAM configtuations will be ignored.

### DPDK parameters
If given, The DPDK configuration expected to have the following parameters

* `kernel_driver` (string, required): kernel driver name
* `dpdk_driver` (string, required): DPDK capable driver name
* `dpdk_tool` (string, required): path to the dpdk-devbind.py script


## Usage

### Configuration with IPAM:

```
# cat > /etc/cni/net.d/10-mynet.conf <<EOF
{
    "name": "mynet",
    "type": "sriov",
    "if0": "enp1s0f1",
    "ipam": {
        "type": "host-local",
        "subnet": "10.55.206.0/26",
        "routes": [
            { "dst": "0.0.0.0/0" }
        ],
        "gateway": "10.55.206.1"
    }
}
EOF
```

```
eth0      Link encap:Ethernet  HWaddr 66:D8:02:77:AA:AA  
          inet addr:10.55.206.46  Bcast:0.0.0.0  Mask:255.255.255.192
          inet6 addr: fe80::64d8:2ff:fe77:aaaa/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:7 errors:0 dropped:0 overruns:0 frame:0
          TX packets:14 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:530 (530.0 b)  TX bytes:988 (988.0 b)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 b)  TX bytes:0 (0.0 b)
```

### Configuration with DPDK:

```
# cat > /etc/cni/net.d/20-mynet-dpdk.conf <<EOF
{
    "name": "mynet",
    "type": "sriov",
    "if0": "enp1s0f1",
    "if0name": "net0",
    "dpdk": {
        "kernel_driver":"ixgbevf",
        "dpdk_driver":"igb_uio",
        "dpdk_tool":"/opt/dpdk/usertools/dpdk-devbind.py"
    }
}
EOF
```

### Configuration with Multiple PFs:

```
# cat > /etc/cni/net.d/10-mynet.conf <<EOF
{
    "name": "mynet",
    "type": "sriov",
    "pfNetdevices": ["enp2s0f0", "enp2s0f1"],
    "ipam": {
        "type": "host-local",
        "subnet": "10.55.206.0/26",
        "routes": [
            { "dst": "0.0.0.0/0" }
        ],
        "gateway": "10.55.206.1"
    }
}
EOF
```

[More info](https://github.com/containernetworking/cni/pull/259).

## Contacts
For any questions about Multus CNI, please reach out on github issue or feel free to contact the developers @kural OR @ahalim in our [Intel-Corp Slack](https://intel-corp.herokuapp.com/)
