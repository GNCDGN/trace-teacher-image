#!/bin/bash
# Build-time (no GPU) check that every flag/parser/spec-method serve.sh uses exists in this vLLM.
set -u
fail=0
echo "vllm: $(python3 -c 'import vllm;print(vllm.__version__)')"
H=$(vllm serve --help=all 2>&1)
for f in --served-model-name --api-key --kv-cache-dtype --gpu-memory-utilization --max-num-seqs --enable-prefix-caching \
         --reasoning-parser --enable-auto-tool-choice --tool-call-parser --language-model-only --speculative-config --max-model-len; do
  echo "$H" | grep -q -- "$f" && echo "flag ok: $f" || { echo "FLAG MISSING: $f"; fail=1; }
done
python3 - <<'PY' || fail=1
import typing, sys
from vllm.config.speculative import SpeculativeMethod
m = set(typing.get_args(SpeculativeMethod)) if typing.get_args(SpeculativeMethod) else set()
def flat(t):
    out=set()
    for a in typing.get_args(t):
        out |= flat(a) if typing.get_args(a) else {a}
    return out
m = flat(SpeculativeMethod)
for x in ("qwen3_5_mtp","mtp"): print("spec method", x, "ok" if x in m else "MISSING")
sys.exit(0 if "qwen3_5_mtp" in m else 1)
PY
python3 - <<'PY' || fail=1
import sys
from vllm.tool_parsers import ToolParserManager as T
names = set(getattr(T, "tool_parsers", {}) .keys()) | set(getattr(T, "lazy_parsers", {}).keys())
for x in ("qwen3_coder","qwen3_xml"): print("tool parser", x, "ok" if x in names else "MISSING")
sys.exit(0 if "qwen3_coder" in names else 1)
PY
echo "reasoning parser qwen3: $(python3 -c 'import vllm.reasoning as r;print(\"qwen3\" in getattr(r.ReasoningParserManager,\"reasoning_parsers\",{}) or \"qwen3\" in getattr(r.ReasoningParserManager,\"lazy_parsers\",{}))' 2>&1 | tail -1)"
exit $fail
