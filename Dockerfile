# === Stage 1: Build environment ===
FROM registry.access.redhat.com/ubi9/ubi as builder

# Install Python and build tools
RUN dnf install -y python3.12 python3.12-devel && \
    python3.11 -m ensurepip && \
    python3.11 -m pip install --upgrade pip && \
    dnf clean all

WORKDIR /build

# Download wheels for all required packages
RUN mkdir /build/wheels && \
    python3.11 -m pip download --no-deps --dest=/build/wheels torch --root-user-action=ignore && \
    python3.11 -m pip download --dest=/build/wheels tabulate scipy numpy pyyaml ctypeslib2 matplotlib pandas --root-user-action=ignore

# === Stage 2: Minimal runtime container ===
FROM registry.access.redhat.com/ubi9/ubi-minimal

# Install minimal Python runtime
RUN microdnf install -y python3.12 numactl-libs && microdnf clean all

# Copy downloaded wheels from builder stage
COPY --from=builder /build/wheels /wheels

# Install wheels directly into system Python
RUN python3.12 -m ensurepip && \
    python3.12 -m pip install --no-cache-dir --find-links=/wheels torch tabulate scipy numpy pyyaml ctypeslib2 matplotlib pandas && \
    rm -rf /wheels /root/.cache/pip

ENV PYTHON_VERSION=3.12 \
    PYTHONUNBUFFERED=1

WORKDIR /workspace

COPY triton-gpu-check.py /workspace/
COPY triton-vector-add-rocm.py /workspace/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
