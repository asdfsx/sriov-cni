#!/bin/bash

if [ ! -e /host-cni-bin/sriov ]; then
	cp /usr/src/sriov-cni/bin/sriov /host-cni-bin/
fi

if [ ! -e /host-cni-bin/fixipam ]; then
	cp -f /usr/src/sriov-cni/bin/fixipam /host-cni-bin/
fi

if [ ! -e /host-cni-etc/10-sriov-cni.conf ]; then
	cp /installer/10-sriov-cni.conf /host-cni-etc/
fi
