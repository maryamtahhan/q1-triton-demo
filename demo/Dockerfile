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

# Install only Python runtime and very basic system libraries
RUN microdnf install -y python3.11 numactl-libs && microdnf clean all

# Copy virtual environment from builder stage (you’d still use a separate builder stage to create it)
COPY --from=builder /build/venv /opt/venv

ENV PATH=/opt/venv/bin:$PATH \
    ROCM_PATH=/rocm-runtime \
    LD_LIBRARY_PATH=/rocm-runtime/lib:/rocm-runtime/llvm/lib:/usr/lib64:/usr/lib

WORKDIR /workspace

COPY triton-gpu-check.py /workspace/
COPY triton-vector-add-rocm.py /workspace/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# podman build -t quay.io/mtahhan/rocm-demo -f Dockerfile .