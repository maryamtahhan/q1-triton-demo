#!/bin/bash

set -e

# Add ROCm repository for RHEL9
cat <<EOF > /etc/yum.repos.d/rocm.repo
[ROCm]
name=ROCm
baseurl=https://repo.radeon.com/rocm/rhel9/6.2/main
enabled=1
gpgcheck=0
EOF

# Install ROCm runtime packages with microdnf
echo "Installing ROCm runtime packages..."
sleep 5
dnf install -y --nodocs --setopt=install_weak_deps=False \
        amd-smi-lib \
        amd-smi \
        miopen-hip \
        rocm-core \
        rocm-hip-libraries \
        rocminfo && \
    dnf clean all && rm -rf /var/cache/yum

# Verify ROCm installation
sleep 3
rocm-smi --showproductname || echo "rocminfo command failed; ROCm driver may not be present."

echo "HIP_VISIBLE_DEVICES=$HIP_VISIBLE_DEVICES"

python /workspace/triton-gpu-check.py || echo "Triton GPU check failed. Possibly missing drivers or runtime libraries."

exec "$@"
