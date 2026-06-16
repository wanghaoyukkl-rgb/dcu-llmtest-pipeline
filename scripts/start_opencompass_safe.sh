#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  start_opencompass_safe.sh <task_id> <container> <config_in_container> <run_dir_host> <work_dir_in_container> [node_ip]

Rules:
  - run_dir_host must be a host path, for example /public/home/.../runs/<ts>.
  - config_in_container and work_dir_in_container must be container paths under /mnt/dcu-llmtest-run.
  - OpenCompass source, when used, must be available at /workspace/opencompass.
  - Never mkdir a /mnt/dcu-llmtest-run path on the host.
USAGE
}

if [ "$#" -lt 5 ] || [ "$#" -gt 6 ]; then
  usage
  exit 2
fi

TASK_ID=$1
CONTAINER=$2
CONFIG_IN_CONTAINER=$3
RUN_DIR_HOST=$4
WORK_DIR_IN_CONTAINER=$5
NODE_IP=${6:-127.0.0.1}
HOST_UID=${HOST_UID:-$(id -u)}
HOST_GID=${HOST_GID:-$(id -g)}

case "${RUN_DIR_HOST}" in
  /mnt/*)
    echo "[ERROR] run_dir_host looks like a container path: ${RUN_DIR_HOST}" >&2
    exit 2
    ;;
  /*) ;;
  *)
    echo "[ERROR] run_dir_host must be an absolute host path: ${RUN_DIR_HOST}" >&2
    exit 2
    ;;
esac

case "${CONFIG_IN_CONTAINER}" in
  /mnt/dcu-llmtest-run/*) ;;
  *)
    echo "[ERROR] config must be a container path under /mnt/dcu-llmtest-run: ${CONFIG_IN_CONTAINER}" >&2
    exit 2
    ;;
esac

case "${WORK_DIR_IN_CONTAINER}" in
  /mnt/dcu-llmtest-run/*) ;;
  *)
    echo "[ERROR] work_dir must be a container path under /mnt/dcu-llmtest-run: ${WORK_DIR_IN_CONTAINER}" >&2
    exit 2
    ;;
esac

mkdir -p "${RUN_DIR_HOST}/reports" "${RUN_DIR_HOST}/${TASK_ID}"
docker inspect "${CONTAINER}" >/dev/null

docker exec \
  -e CONFIG_IN_CONTAINER="${CONFIG_IN_CONTAINER}" \
  "${CONTAINER}" bash -lc '
set -euo pipefail
python_bin=python
command -v python >/dev/null 2>&1 || python_bin=python3
export PYTHONPATH=/workspace/opencompass:${PYTHONPATH:-}

[ -f "${CONFIG_IN_CONTAINER}" ] || {
  echo "[ERROR] OpenCompass config not found in container: ${CONFIG_IN_CONTAINER}" >&2
  exit 20
}

if [ -f /workspace/opencompass/run.py ]; then
  "${python_bin}" - <<'"'"'PY'"'"'
from mmengine.config import read_base  # noqa: F401
from opencompass.cli.main import main  # noqa: F401
PY
else
  command -v opencompass >/dev/null || {
    echo "[ERROR] OpenCompass is not installed and /workspace/opencompass/run.py is missing" >&2
    exit 21
  }
  "${python_bin}" - <<'"'"'PY'"'"'
from mmengine.config import read_base  # noqa: F401
from opencompass.cli.main import main  # noqa: F401
PY
fi
'

docker exec \
  -u "${HOST_UID}:${HOST_GID}" \
  -e TASK_ID="${TASK_ID}" \
  -e CONFIG_IN_CONTAINER="${CONFIG_IN_CONTAINER}" \
  -e WORK_DIR_IN_CONTAINER="${WORK_DIR_IN_CONTAINER}" \
  -e NODE_IP="${NODE_IP}" \
  "${CONTAINER}" bash -lc '
set -euo pipefail
python_bin=python
command -v python >/dev/null 2>&1 || python_bin=python3

mkdir -p "${WORK_DIR_IN_CONTAINER}/logs/launcher" "/tmp/opencompass-home-${TASK_ID}"
export HOME="/tmp/opencompass-home-${TASK_ID}"

log_file="${WORK_DIR_IN_CONTAINER}/logs/launcher/start.log"
pid_file="${WORK_DIR_IN_CONTAINER}/logs/launcher/pid"
rm -f "${pid_file}"

(
  set -euo pipefail
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
  export no_proxy="${NODE_IP},localhost,127.0.0.1"
  export NO_PROXY="${NODE_IP},localhost,127.0.0.1"
  export COMPASS_DATA_CACHE=/mnt/opencompass
  export PYTHONPATH=/workspace/opencompass:${PYTHONPATH:-}
  cd /mnt/dcu-llmtest-run
  if [ -f /workspace/opencompass/run.py ]; then
    exec "${python_bin}" /workspace/opencompass/run.py "${CONFIG_IN_CONTAINER}"
  else
    exec opencompass "${CONFIG_IN_CONTAINER}"
  fi
) >"${log_file}" 2>&1 &

echo "$!" >"${pid_file}"
sleep 5
pid=$(cat "${pid_file}")
if ! ps -p "${pid}" >/dev/null 2>&1; then
  echo "[ERROR] OpenCompass exited during startup; log=${log_file}" >&2
  tail -n 10 "${log_file}" >&2 || true
  exit 30
fi
if grep -qiE "Traceback|ModuleNotFoundError|ImportError|No such file|command not found|Permission denied" "${log_file}"; then
  echo "[ERROR] OpenCompass startup log contains an error; log=${log_file}" >&2
  tail -n 10 "${log_file}" >&2 || true
  exit 31
fi

echo "opencompass started ${TASK_ID} pid=${pid} work_dir=${WORK_DIR_IN_CONTAINER} log=${log_file}"
'
