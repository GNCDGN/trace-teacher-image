# trace-llama: llama.cpp b9585 (the UK box's build) with CUDA 13, built once (~45 min) and consumed by COPY --from in the train image.
FROM nvidia/cuda:13.0.0-devel-ubuntu24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends git cmake ninja-build build-essential ca-certificates && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch b9585 https://github.com/ggml-org/llama.cpp /opt/llama.cpp
WORKDIR /opt/llama.cpp
RUN cmake -B build -G Ninja -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="80;86;90" -DLLAMA_CURL=OFF -DBUILD_SHARED_LIBS=OFF -DGGML_NATIVE=OFF -DCMAKE_BUILD_TYPE=Release \
 && cmake --build build --target llama-quantize llama-server llama-cli llama-perplexity llama-gguf-split \
 && mkdir -p bin && cp build/bin/llama-* bin/ && rm -rf build .git
LABEL org.opencontainers.image.source="https://github.com/GNCDGN/trace-teacher-image"
