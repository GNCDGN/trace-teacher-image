# trace-train r1: the teacher image (torch 2.13+cu130, transformers 5.17.0, sshd, podwatch) + Unsloth/PEFT/TRL/bitsandbytes/fla. No vLLM (removed), no llama.cpp (r2 adds it).
# Training scripts are NOT baked in (scp'd / on the volume). Constraints are derived from what the base image already ships so pip never swaps torch.
FROM ghcr.io/gncdgn/trace-teacher:vllm0.31.0-r2
RUN pip uninstall -y vllm >/dev/null 2>&1; \
    pip freeze 2>/dev/null | grep -i -E '^(torch|torchvision|torchaudio|triton|transformers|tokenizers|numpy|safetensors|huggingface[-_]hub)==' > /opt/trace/constraints.txt; cat /opt/trace/constraints.txt; \
    pip install --no-cache-dir -c /opt/trace/constraints.txt \
      unsloth==2026.10.3 unsloth_zoo==2026.10.3 peft==0.21.2 trl==1.13.0 bitsandbytes==0.50.2 accelerate==1.15.0 datasets==4.8.5 \
      flash-linear-attention==0.5.2 hf_transfer pyyaml sentencepiece protobuf \
 && pip freeze > /opt/trace/train-freeze.txt
RUN python3 -c "import torch,transformers,peft,trl,bitsandbytes,accelerate,fla,datasets;print('stack ok',torch.__version__,torch.version.cuda,transformers.__version__,peft.__version__,trl.__version__,bitsandbytes.__version__,datasets.__version__)"
LABEL org.opencontainers.image.source="https://github.com/GNCDGN/trace-teacher-image"
