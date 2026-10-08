#!/bin/bash
# vLLM teacher server. Flags from TRACE-RUN-PLAN 3.7 / the vLLM recipe for Qwen3.8-27B, checked against v0.31.0.
[ -f /etc/trace-env ] && . /etc/trace-env
MODEL="${MODEL_DIR:-/workspace/models/Qwen3.8-27B-FP8}"
[ -f "$MODEL/config.json" ] || { echo "FATAL weights missing at $MODEL"; exit 1; }
: "${TEACHER_KEY:?FATAL TEACHER_KEY not set}"
export HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 VLLM_NO_USAGE_STATS=1 DO_NOT_TRACK=1
unset RUNPOD_API_KEY
SPEC="{\"method\":\"${SPEC_METHOD:-qwen3_5_mtp}\",\"num_speculative_tokens\":${NUM_SPEC:-3}}"
ARGS=(--served-model-name teacher --api-key "$TEACHER_KEY" --host 127.0.0.1 --port 8000
  --max-model-len "${MAX_MODEL_LEN:-65536}" --kv-cache-dtype fp8 --gpu-memory-utilization "${GPU_UTIL:-0.92}"
  --max-num-seqs "${MAX_NUM_SEQS:-96}" --enable-prefix-caching
  --reasoning-parser qwen3 --enable-auto-tool-choice --tool-call-parser "${TOOL_PARSER:-qwen3_coder}"
  --language-model-only)
[ "${NUM_SPEC:-3}" != 0 ] && ARGS+=(--speculative-config "$SPEC")
# shellcheck disable=SC2086
exec vllm serve "$MODEL" "${ARGS[@]}" ${EXTRA_ARGS:-}
