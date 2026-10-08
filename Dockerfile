# trace-teacher: pinned vLLM + ssh + the serve/start/pod-watchdog scripts. No pip/apt happens on a billed pod.
FROM vllm/vllm-openai:v0.31.0-ubuntu2404
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-server rsync tmux curl jq procps iproute2 git ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /run/sshd /opt/trace
RUN python3 -c "import torch, vllm.engine.arg_utils as a; print('import ok', torch.__version__, vllm.__version__ if False else '')"
COPY start.sh serve.sh podwatch.sh verify_flags.sh /opt/trace/
RUN chmod +x /opt/trace/*.sh && (/opt/trace/verify_flags.sh 2>&1 | tee /opt/trace/FLAGCHECK.txt; true)
LABEL org.opencontainers.image.source="https://github.com/GNCDGN/trace-teacher-image"
ENTRYPOINT ["/opt/trace/start.sh"]
CMD []
