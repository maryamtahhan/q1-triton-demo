FROM registry.access.redhat.com/ubi9/python-311

USER 0

# Set environment variables for ROCm
ENV LC_ALL=C.UTF-8 \
LANG=C.UTF-8 \
ROCM_PATH=/opt/rocm \
LD_LIBRARY_PATH=/usr/lib64:/usr/lib:/opt/rocm/lib:/opt/rocm/llvm/lib \
PATH=/opt/rocm/bin:/opt/rocm/llvm/bin:$PATH

# Create the /workspace directory and set permissions
RUN mkdir -p /workspace && \
    python -m venv /workspace && \
    echo "unset BASH_ENV PROMPT_COMMAND ENV" >> /workspace/bin/activate && \
    chmod -R 777 /workspace

ENV BASH_ENV=/workspace/bin/activate \
    ENV=/workspace/bin/activate \
    PROMPT_COMMAND=". /workspace/bin/activate" \
    PYTHON_VERSION=3.11 \
    PATH=/workspace/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PIP_PREFIX=/workspace \
    PYTHONPATH=/workspace/lib/python$PYTHON_VERSION/site-packages \
    XDG_CACHE_HOME=/workspace \
    TRITON_CACHE_DIR=/workspace/.triton/cache \
    TRITON_HOME=/workspace/

WORKDIR /workspace

RUN /workspace/bin/activate && pip install --upgrade pip && pip install --no-cache-dir tabulate scipy numpy pyyaml ctypeslib2 matplotlib pandas && \
    pip install --no-cache-dir torch==2.5.0 --index-url https://download.pytorch.org/whl/rocm6.2

COPY triton-gpu-check.py /workspace/
COPY triton-vector-add.py /workspace/
COPY triton-flash-attention.py /workspace/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# [ podman | docker ]  build -t quay.io/mtahhan/rocm-demo -f Dockerfile .
