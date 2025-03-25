#!/bin/bash
set -e

python /workspace/triton-gpu-check.py

# Execute the container’s default CMD or passed args
exec "$@"
