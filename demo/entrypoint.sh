#!/bin/bash
set -e

# Add ROCm repo
cat <<EOF > /etc/yum.repos.d/rocm.repo
[ROCm]
name=ROCm
baseurl=https://repo.radeon.com/rocm/rhel9/6.2/main
enabled=1
gpgcheck=0
EOF

# Install runtime libraries
microdnf install -y amd-smi-lib \
        amd-smi \
        miopen-hip \
        rocm-core \
        rocm-hip-libraries \
        rocminfo \
        llvm  \
        clang \
        lld

# Clean up
microdnf clean all

# Execute the container’s default CMD or passed args
exec "$@"
