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

# Install wheels into system Python
pip install --upgrade pip && pip install --no-cache-dir tabulate scipy numpy pyyaml ctypeslib2 matplotlib pandas && \
    pip install --no-cache-dir torch==2.5.0 --index-url https://download.pytorch.org/whl/rocm6.2

echo "HIP_VISIBLE_DEVICES=$HIP_VISIBLE_DEVICES"

python /workspace/triton-gpu-check.py || echo "Triton GPU check failed. Possibly missing drivers or runtime libraries."

exec "$@"
