#!/bin/bash
# On-pod dead-man (secondary to the VPS watchdog). Terminates THIS pod, using the pod-scoped key RunPod injects
# (not the operator's account key), when: the absolute deadline passes, or the VPS heartbeat file goes stale,
# or no heartbeat ever arrives. Armed only while POD_WATCHDOG=1. Never stops: terminates.
[ -f /etc/trace-env ] && . /etc/trace-env
POD="${RUNPOD_POD_ID:?}"
RUN_DIR="${RUN_DIR:-/workspace/run/$POD}"
HB="$RUN_DIR/vps.heartbeat"
GRACE="${HB_GRACE_S:-1200}"          # heartbeat staleness allowed
FIRST="${HB_FIRST_S:-1500}"          # time allowed for the first heartbeat
DEADLINE="${POD_DEADLINE_EPOCH:-0}"  # absolute epoch; 0 = none
KEY=$(tr '\0' '\n' < /proc/1/environ | sed -n 's/^RUNPOD_API_KEY=//p')
START=$(date +%s)
term() {
  echo "$(date -u +%FT%TZ) TERMINATING self: $1"
  curl -s -m 30 -A curl/8.4 -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
    -d "{\"query\":\"mutation { podTerminate(input: {podId: \\\"$POD\\\"}) }\"}" https://api.runpod.io/graphql
  echo; sleep 120   # if still alive, retry below
}
echo "$(date -u +%FT%TZ) podwatch armed pod=$POD deadline=$DEADLINE grace=$GRACE first=$FIRST"
while true; do
  now=$(date +%s)
  if [ "$DEADLINE" -gt 0 ] && [ "$now" -ge "$DEADLINE" ]; then term "deadline"; continue; fi
  if [ -f "$HB" ]; then
    age=$(( now - $(stat -c %Y "$HB") ))
    [ "$age" -gt "$GRACE" ] && { term "heartbeat stale ${age}s"; continue; }
  else
    [ $(( now - START )) -gt "$FIRST" ] && { term "no heartbeat ever"; continue; }
  fi
  sleep 20
done
