#!/bin/bash
# Container entrypoint (RunPod pod). Sets up ssh from PUBLIC_KEY, optionally autostarts vLLM and the on-pod dead-man.
mkdir -p /root/.ssh /run/sshd
chmod 700 /root/.ssh
if [ -n "${PUBLIC_KEY:-}" ]; then
  echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys; chmod 600 /root/.ssh/authorized_keys
fi
# env for ssh sessions and child scripts: only our own vars, never RUNPOD_API_KEY
( umask 077; env | grep -E '^(TEACHER_|MODEL_|MAX_|GPU_|NUM_SPEC|EXTRA_ARGS|POD_|HB_|AUTOSTART_|CAP_|RUNPOD_POD_ID|RUNPOD_DC_ID|HF_HUB_)' \
  | sed -e 's/\\/\\\\/g' -e "s/'/'\\\\''/g" -e "s/^\([A-Za-z_0-9]*\)=\(.*\)$/export \1='\2'/" > /etc/trace-env )
grep -q trace-env /root/.bashrc 2>/dev/null || echo '[ -f /etc/trace-env ] && . /etc/trace-env' >> /root/.bashrc
ssh-keygen -A >/dev/null 2>&1
/usr/sbin/sshd -o PermitRootLogin=prohibit-password -o PasswordAuthentication=no
RUN_DIR=/workspace/run/${RUNPOD_POD_ID:-local}
mkdir -p "$RUN_DIR"; export RUN_DIR
echo "$(date -u +%FT%TZ) container up, image trace-teacher, pod=${RUNPOD_POD_ID:-?}" >> "$RUN_DIR/start.log"
if [ "${POD_WATCHDOG:-0}" = 1 ]; then setsid nohup /opt/trace/podwatch.sh >> "$RUN_DIR/podwatch.log" 2>&1 & fi
if [ "${AUTOSTART_VLLM:-0}" = 1 ]; then setsid nohup /opt/trace/serve.sh >> "$RUN_DIR/vllm.log" 2>&1 & fi
exec sleep infinity
