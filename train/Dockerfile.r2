# trace-train r2 = r1 + llama.cpp b9585 binaries (CUDA) + convert_hf_to_gguf.py and its python deps
FROM ghcr.io/gncdgn/trace-llama:b9585 AS llama
FROM ghcr.io/gncdgn/trace-train:u2026.10.3-r1
COPY --from=llama /opt/llama.cpp /opt/llama.cpp
RUN pip install --no-cache-dir --no-deps -e /opt/llama.cpp/gguf-py \
 && pip freeze > /opt/trace/train-freeze.txt
ENV PATH=/opt/llama.cpp/bin:$PATH
RUN ls /opt/llama.cpp/bin && (ldd /opt/llama.cpp/bin/llama-server | grep -i "not found" || echo "no missing libs") | tee /opt/trace/llama-ldd.txt && python3 -c "import gguf;print('gguf ok')"
LABEL org.opencontainers.image.source="https://github.com/GNCDGN/trace-teacher-image"
