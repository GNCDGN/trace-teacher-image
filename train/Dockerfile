# trace-train: the teacher image (torch 2.13+cu130, transformers 5.17.0, sshd, podwatch) + Unsloth/PEFT/TRL stack + llama.cpp b9585 (CUDA).
# Built on the teacher image so hosts that already pulled it only fetch the new layers. Training scripts are NOT baked in (copied from the volume / scp).
FROM nvidia/cuda:13.0.0-devel-ubuntu24.04 AS llama
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends git cmake build-essential ca-certificates && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch b9585 https://github.com/ggml-org/llama.cpp /opt/llama.cpp
WORKDIR /opt/llama.cpp
RUN cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="80;86;89;90" -DLLAMA_CURL=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release \
 && cmake --build build -j"$(nproc)" --target llama-quantize llama-server llama-cli llama-perplexity llama-gguf-split \
 && mkdir -p bin && cp build/bin/llama-* bin/ && rm -rf build .git

FROM ghcr.io/gncdgn/trace-teacher:vllm0.31.0-r2
COPY --from=llama /opt/llama.cpp /opt/llama.cpp
COPY constraints.txt /opt/trace/constraints.txt
RUN pip uninstall -y vllm >/dev/null 2>&1; \
    pip install --no-cache-dir -c /opt/trace/constraints.txt \
      unsloth==2026.10.3 unsloth_zoo==2026.10.3 peft==0.21.2 trl==1.13.0 bitsandbytes==0.50.2 accelerate==1.15.0 datasets==5.1.0 \
      flash-linear-attention==0.5.2 hf_transfer pyyaml sentencepiece protobuf numpy \
 && pip install --no-cache-dir -r /opt/llama.cpp/requirements/requirements-convert_hf_to_gguf.txt -c /opt/trace/constraints.txt \
 && pip install --no-cache-dir -e /opt/llama.cpp/gguf-py -c /opt/trace/constraints.txt \
 && pip freeze > /opt/trace/train-freeze.txt
ENV PATH=/opt/llama.cpp/bin:$PATH
RUN python3 -c "import torch,transformers,peft,trl,bitsandbytes,accelerate,fla,gguf;print('stack ok',torch.__version__,torch.version.cuda,transformers.__version__,peft.__version__,trl.__version__,bitsandbytes.__version__)" \
 && ls /opt/llama.cpp/bin && (ldd /opt/llama.cpp/bin/llama-server | grep -i "not found" || true) | tee /opt/trace/llama-ldd-missing.txt \
 && /opt/llama.cpp/bin/llama-quantize --help 2>&1 | head -2 || true
LABEL org.opencontainers.image.source="https://github.com/GNCDGN/trace-teacher-image"
