#!/bin/bash

# Base configuration with defaults
MODE=${MODE:-"serve"}
MODEL=${MODEL:-"Qwen/Qwen1.5-MoE-A2.7B-Chat"}
PORT=${PORT:-8000}

# Benchmark configuration with defaults
INPUT_LEN=${INPUT_LEN:-512}
OUTPUT_LEN=${OUTPUT_LEN:-256}
NUM_PROMPTS=${NUM_PROMPTS:-1000}
NUM_ROUNDS=${NUM_ROUNDS:-3}
MAX_BATCH_TOKENS=${MAX_BATCH_TOKENS:-8192}
NUM_CONCURRENT=${NUM_CONCURRENT:-8}

# Additional args passed directly to vLLM
EXTRA_ARGS=${EXTRA_ARGS:-""}

# Log file location
LOG_PATH="/tmp/vllm.log"

summarize_logs() {
  local logfile="$1"
  echo -e "\n===== Startup Summary ====="
  awk '
    /Loading weights took/ {
      print " Weight Load Time:    " $(NF-1), "seconds"
    }
    /Model loading took/ {
      print " Model Load Time:     " $(NF-1), "seconds"
    }
    /Memory profiling takes/ {
      print " Memory Profile Time: " $(NF-1), "seconds"
    }
    /Graph capturing finished/ {
      for (i=1; i<NF; i++) {
        if ($i == "in" && $(i+1) ~ /^[0-9.]+$/ && $(i+2) == "secs,") {
          print " CUDA Graphs Time:    " $(i+1), "seconds"
        }
      }
    }
    /init engine.*took/ {
      print " Total Startup Time:  " $(NF-1), "seconds"
    }
  ' "$logfile"
  echo "============================="
}


watch_for_startup_complete() {
  local logfile="$1"
  while read -r line; do
    echo "$line" >> "$logfile"
    if echo "$line" | grep -q "Application startup complete"; then
      summarize_logs "$logfile"
      break
    fi
  done
}

case $MODE in
  "serve")
    echo "Starting vLLM server on port $PORT with model: $MODEL"
    echo "Additional arguments: $EXTRA_ARGS"

    # Kick off the server, stream stdout and stderr, and monitor output live
    (
      # Run summarizer watcher in background
      tail -F "$LOG_PATH" | while read -r line; do
        echo "$line"
        if [[ "$line" == *"Application startup complete."* ]]; then
          summarize_logs "$LOG_PATH"
          break
        fi
      done
    ) &

    # Start vLLM and tee everything to the log file
    python3 -u -m vllm.entrypoints.openai.api_server \
      --model "$MODEL" \
      --port "$PORT" \
      $EXTRA_ARGS > "$LOG_PATH" 2>&1
    ;;

  "benchmark")
    echo "Running vLLM benchmarks with model: $MODEL"
    echo "Additional arguments: $EXTRA_ARGS"

    # Create timestamped directory for this benchmark run
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BENCHMARK_DIR="/data/benchmarks/$TIMESTAMP"
    mkdir -p "$BENCHMARK_DIR"

    echo "Running throughput benchmark..."
    python3 /app/vllm/benchmarks/benchmark_throughput.py \
      --model "$MODEL" \
      --input-len "$INPUT_LEN" \
      --output-len "$OUTPUT_LEN" \
      --num-prompts "$NUM_PROMPTS" \
      --max-num-batched-tokens "$MAX_BATCH_TOKENS" \
      --output-json "$BENCHMARK_DIR/throughput.json" \
      $EXTRA_ARGS
    echo "Throughput benchmark complete - results saved in $BENCHMARK_DIR/throughput.json"

    echo "Running latency benchmark..."
    python3 /app/vllm/benchmarks/benchmark_latency.py \
      --model "$MODEL" \
      --input-len "$INPUT_LEN" \
      --output-len "$OUTPUT_LEN" \
      --output-json "$BENCHMARK_DIR/latency.json" \
      $EXTRA_ARGS
    echo "Latency benchmark complete - results saved in $BENCHMARK_DIR/latency.json"

    echo "All results have been saved to $BENCHMARK_DIR"
    ;;

  *)
    echo "Unknown mode: $MODE"
    echo "Please use 'serve' or 'benchmark'"
    exit 1
    ;;
esac
