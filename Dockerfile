# === Stage 1: Build environment ===
FROM registry.access.redhat.com/ubi9/ubi as builder

# Install Python and build tools
RUN dnf install -y python3.11 python3.11-devel gcc gcc-c++ cmake make && \
    python3.11 -m ensurepip && \
    python3.11 -m pip install --upgrade pip && \
    dnf clean all

WORKDIR /build

# Create isolated virtual environment
RUN python3.11 -m venv /build/venv

# Install required Python packages into venv
RUN /build/venv/bin/pip install --disable-pip-version-check --no-cache-dir torch --index-url https://download.pytorch.org/whl/rocm6.2 --root-user-action=ignore && \
    /build/venv/bin/pip install --disable-pip-version-check --no-cache-dir tabulate scipy numpy pyyaml ctypeslib2 matplotlib pandas --root-user-action=ignore


# === Stage 2: Minimal runtime container ===
FROM registry.access.redhat.com/ubi9/ubi-minimal

# Install Python runtime and minimal dependencies
RUN microdnf install -y python3.11 numactl-libs && microdnf clean all

# Copy virtual environment from builder stage
COPY --from=builder /build/venv /opt/venv

# ROCm & Triton environment variables
ENV ROCM_PATH=/opt/rocm \
    LD_LIBRARY_PATH=/usr/lib64:/usr/lib:/opt/rocm/lib:/opt/rocm/llvm/lib \
    PATH=/opt/venv/bin:/opt/rocm/bin:/opt/rocm/llvm/bin:$PATH \
    ROCM_VERSION=6.2 \
    PIP_PREFIX=/build/venv

WORKDIR /workspace

# Copy the GPU check and demo script
COPY triton-gpu-check.py /workspace/
COPY triton-vector-add-rocm.py /workspace/
# Add ROCm repo and install runtime libraries
RUN echo "[ROCm]" > /etc/yum.repos.d/rocm.repo && \
    echo "name=ROCm" >> /etc/yum.repos.d/rocm.repo && \
    echo "baseurl=https://repo.radeon.com/rocm/rhel9/6.2/main" >> /etc/yum.repos.d/rocm.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/rocm.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/rocm.repo && \
    microdnf install -y amd-smi-lib amd-smi rocm-core rocm-hip-libraries rocminfo miopen-hip llvm clang lld && \
    microdnf clean all

ENTRYPOINT ["/entrypoint.sh"]
# podman build -t quay.io/mtahhan/rocm-demo -f Dockerfile .