#!/bin/bash

cleanup() {
    echo "Running cleanup..."
    sudo kubeadm reset -f
    rm -rf $HOME/.kube/
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    sudo systemctl restart crio
    sudo ls /etc/cni/net.d
    sudo rm -rf /etc/cni/net.d/*
    sudo swapoff -av
    sudo free -h
    sudo setenforce 1
    echo "Cleanup completed."
}

init() {
    sudo modprobe br_netfilter
    sudo bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
}

create() {
    echo "Running Kubernetes init and setup..."
    sudo setenforce 0
    sudo kubeadm init --v 99 --pod-network-cidr=10.244.0.0/16 --cri-socket /var/run/crio/crio.sock
    rm -f $HOME/.kube/config
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true
    kubectl get nodes
    kubectl describe node
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
    kubectl describe node
    kubectl create -f https://raw.githubusercontent.com/ROCm/k8s-device-plugin/master/k8s-ds-amdgpu-dp.yaml
    kubectl create -f https://raw.githubusercontent.com/ROCm/k8s-device-plugin/master/k8s-ds-amdgpu-labeller.yaml
    echo "Cluster creation and configuration completed."
}

# Main execution
if [ "$1" == "cleanup" ]; then
    cleanup
elif [ "$1" == "create" ]; then
    create
elif [ "$1" == "init" ]; then
    init
else
    cleanup
    init
    create
fi
