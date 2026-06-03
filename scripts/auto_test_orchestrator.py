#!/usr/bin/env python3
"""DCU LLM 长队列测试后台编排器。

这个脚本用于执行已经确认的多模型/多波次测试计划，适合跨小时或跨天运行。
它运行在后台，不依赖 Codex/Agent 会话保持在线。

设计原则偏保守：
- 读取用户确认后的 plan.json。
- 仅在节点和卡资源空闲时启动 pending 任务。
- evalscope 快速验证和 OpenCompass 正式验证都使用同一套任务 watcher 字段。
- 模型服务 ready 后执行一次 curl 聊天请求；响应异常或乱码时记录失败并释放资源。
- 遇到 error/aborted/timeout/curl 响应乱码时记录失败，释放当前任务资源，
  然后继续调度后续 pending 任务。

典型用法：
  nohup python3 auto_test_orchestrator.py --plan <run_dir>/plan.json --run-dir <run_dir> \
    > <run_dir>/orchestrator.log 2>&1 &

主要输出：
- state.json：当前任务状态，可用于恢复和查询。
- events.log：任务启动、完成、失败、释放资源等事件流水。
- reports/test_report.md：随任务执行持续刷新的简洁 Markdown 测试报告。
- reports/task_plan.md：按用户确认计划执行的四态 Markdown 任务计划表。
"""

import argparse
import datetime as dt
import json
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


TERMINAL = {"done", "failed", "aborted", "released", "skipped"}
RUNNING = {"starting", "running"}
PLAN_STATUS = {"pending": "待测试", "running": "测试中", "done": "通过", "failed": "异常"}
PROBE_PROMPT = "介绍一下人工智能发展史"
HTTP_STATUS_MARKER = "__HTTP_STATUS__:"


def now() -> str:
    return dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def iso_ts() -> str:
    return dt.datetime.now().isoformat(timespec="seconds")


def parse_iso_ts(value) -> dt.datetime:
    text = str(value)
    # Python 3.6 in some DCU environments has no datetime.fromisoformat.
    normalized = text.replace("T", " ")[:19]
    return dt.datetime.strptime(normalized, "%Y-%m-%d %H:%M:%S")


def load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def atomic_write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    tmp.replace(path)


def append_event(events_log: Path, task_id: str, event: str, detail: str = "") -> None:
    events_log.parent.mkdir(parents=True, exist_ok=True)
    record = {
        "time": now(),
        "task_id": task_id,
        "event": event,
        "detail": detail,
    }
    line = json.dumps(record, ensure_ascii=False)
    with events_log.open("a", encoding="utf-8") as fh:
        fh.write(line + "\n")
    print(line, flush=True)


def is_local_node(node):
    return not node or node in {"localhost", "127.0.0.1", "::1", "local"}


def run_shell(command, node=None, timeout=None):
    if is_local_node(node):
        cmd = command
    else:
        cmd = "ssh -o BatchMode=yes " + shlex.quote(str(node)) + " " + shlex.quote(command)
    return subprocess.run(
        cmd,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        timeout=timeout,
    )


def choose_poll_interval(args, plan):
    if args.poll_interval is not None:
        return int(args.poll_interval)
    for key in ("watch_interval_sec", "poll_interval_sec"):
        if plan.get(key):
            return int(plan[key])
    mode = str(plan.get("watch_mode") or plan.get("task_duration") or "").lower()
    if plan.get("long_task") or mode in {"long", "long_task", "long-running", "长任务", "长时间"}:
        return 1800
    return 600


def compact_text(value, limit=120):
    text = str(value or "").replace("\n", " ").replace("\r", " ").strip()
    text = re.sub(r"\s+", " ", text)
    if len(text) > limit:
        return text[: limit - 3] + "..."
    return text


def markdown_cell(value, limit=80):
    text = compact_text(value, limit).replace("|", "/")
    return text or "-"


def stringify_content(value):
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        parts = []
        for item in value:
            if isinstance(item, dict):
                parts.append(str(item.get("text") or item.get("content") or ""))
            else:
                parts.append(str(item))
        return " ".join(x for x in parts if x)
    return "" if value is None else str(value)


def extract_response_text(obj):
    if isinstance(obj, str):
        return obj
    if isinstance(obj, list):
        return " ".join(extract_response_text(item) for item in obj)
    if not isinstance(obj, dict):
        return ""
    choices = obj.get("choices")
    if isinstance(choices, list) and choices:
        first = choices[0]
        if isinstance(first, dict):
            message = first.get("message")
            if isinstance(message, dict):
                text = stringify_content(message.get("content"))
                if text:
                    return text
            text = stringify_content(first.get("text") or first.get("content"))
            if text:
                return text
        return extract_response_text(first)
    for key in ("content", "response", "output", "text", "generated_text", "completion"):
        text = stringify_content(obj.get(key))
        if text:
            return text
    return ""


def looks_garbled(text):
    s = str(text or "").strip()
    if not s:
        return False
    if "\ufffd" in s or "\\ufffd" in s:
        return True
    if re.search(r"([\W_])\1{7,}", s):
        return True
    if len(s) >= 12:
        useful = sum(
            ch.isalnum()
            or "\u4e00" <= ch <= "\u9fff"
            or ch in " .,;:!?+-=*/()[]{}<>%$#@'\"\n\t"
            for ch in s
        )
        return useful / max(len(s), 1) < 0.35
    return False


def default_probe_url(task):
    explicit = task.get("probe_url")
    if explicit:
        return str(explicit)
    base = task.get("openai_api_base") or task.get("api_base")
    if base:
        base = str(base).rstrip("/")
        if base.endswith("/v1/chat/completions"):
            return base
        if base.endswith("/v1"):
            return base + "/chat/completions"
        return base + "/v1/chat/completions"
    host = task.get("probe_host") or "127.0.0.1"
    port = task.get("port") or task.get("api_port") or 8000
    return f"http://{host}:{port}/v1/chat/completions"


def served_model_path(task):
    for key in ("served_model_path", "container_model_path", "model_path", "path"):
        if task.get(key):
            return str(task[key])
    model = str(task.get("model") or "model").strip("/") or "model"
    return "/model/" + model


def build_probe_cmd(task):
    url = default_probe_url(task)
    payload = {
        "model": served_model_path(task),
        "messages": [{"role": "user", "content": PROBE_PROMPT}],
        "max_tokens": int(task.get("probe_max_tokens", 500) or 500),
        "temperature": float(task.get("probe_temperature", 0.0) or 0.0),
    }
    timeout = int(task.get("probe_timeout_sec", 120) or 120)
    task["probe_url"] = url
    task["served_model_path"] = payload["model"]
    return (
        "curl -sS --max-time "
        + shlex.quote(str(timeout))
        + " -w "
        + shlex.quote("\n" + HTTP_STATUS_MARKER + "%{http_code}")
        + " "
        + shlex.quote(url)
        + " -H "
        + shlex.quote("Content-Type: application/json")
        + " -d "
        + shlex.quote(json.dumps(payload, ensure_ascii=False))
    )


def parse_probe_output(raw):
    text = raw or ""
    http_status = ""
    marker_pos = text.rfind(HTTP_STATUS_MARKER)
    if marker_pos >= 0:
        body = text[:marker_pos].strip()
        http_status = text[marker_pos + len(HTTP_STATUS_MARKER) :].strip().splitlines()[0]
    else:
        body = text.strip()
    if http_status and not http_status.startswith(("2", "3")):
        return {"status": "error", "detail": f"curl HTTP {http_status}", "body": compact_text(body, 500)}
    try:
        obj = json.loads(body)
    except Exception:
        return {"status": "error", "detail": "curl 响应不是有效 JSON", "body": compact_text(body, 500)}
    answer = extract_response_text(obj).strip()
    if not answer:
        return {"status": "error", "detail": "curl 响应中未提取到文本", "body": compact_text(body, 500)}
    if looks_garbled(answer):
        return {"status": "garbled", "detail": "curl 响应疑似乱码", "sample": compact_text(answer, 200)}
    return {"status": "ok", "detail": "curl 请求正常", "sample": compact_text(answer, 200)}


def run_service_probe(task_state):
    cmd = task_state.get("probe_cmd") or build_probe_cmd(task_state)
    proc = run_shell(str(cmd), task_state.get("node"), timeout=int(task_state.get("probe_timeout_sec", 120) or 120))
    output = (proc.stdout + proc.stderr).strip()
    if proc.returncode != 0:
        return {"status": "error", "detail": "curl 命令执行失败", "body": compact_text(output, 500)}
    result = parse_probe_output(proc.stdout)
    if proc.stderr.strip() and result.get("status") == "ok":
        result["stderr"] = compact_text(proc.stderr, 200)
    return result


def get_task_id(task):
    return str(task.get("task_id") or task.get("id") or task.get("model") or "task")


def cards(task):
    raw = task.get("cards") or task.get("card_ids") or task.get("cardID") or []
    if isinstance(raw, str):
        raw = [x.strip() for x in re.split(r"[, ]+", raw) if x.strip()]
    return {str(x) for x in raw}


def resources_free(task, state_tasks, max_parallel_without_cards):
    node = str(task.get("node") or "local")
    wanted = cards(task)
    active_no_card = 0
    for other in state_tasks.values():
        if other.get("status") not in RUNNING:
            continue
        if str(other.get("node") or "local") != node:
            continue
        occupied = cards(other)
        if wanted and occupied and wanted.intersection(occupied):
            return False
        if not wanted or not occupied:
            active_no_card += 1
    if not wanted:
        return active_no_card < max_parallel_without_cards
    return True


def task_sort_key(task):
    return (
        int(task.get("wave", 0) or 0),
        int(task.get("priority", task.get("order", 1000)) or 1000),
        get_task_id(task),
    )


def default_release_cmd(task):
    container = task.get("container")
    if not container:
        return ""
    return "docker stop " + shlex.quote(str(container))


def release_task(task_state, events_log, reason):
    task_id = get_task_id(task_state)
    cmd = task_state.get("release_cmd") or default_release_cmd(task_state)
    if not cmd:
        task_state["release_status"] = "no_release_cmd"
        append_event(events_log, task_id, "release_skipped", reason)
        return
    proc = run_shell(str(cmd), task_state.get("node"), timeout=int(task_state.get("release_timeout_sec", 120)))
    task_state["release_status"] = "released" if proc.returncode == 0 else "release_failed"
    task_state["released_at"] = iso_ts()
    detail = (proc.stdout + proc.stderr).strip()[-1000:]
    append_event(events_log, task_id, task_state["release_status"], reason + ("; " + detail if detail else ""))


def start_task(task_state, events_log):
    task_id = get_task_id(task_state)
    cmd = task_state.get("start_cmd")
    if not cmd:
        task_state["status"] = "failed"
        task_state["result"] = "缺少 start_cmd"
        task_state["finished_at"] = iso_ts()
        append_event(events_log, task_id, "failed", "缺少 start_cmd")
        release_task(task_state, events_log, "缺少 start_cmd")
        return
    task_state["status"] = "starting"
    task_state["started_at"] = task_state.get("started_at") or iso_ts()
    task_state["probe_checked"] = bool(task_state.get("probe_checked", False))
    if task_state.get("eval_start_cmd"):
        task_state["eval_started"] = bool(task_state.get("eval_started", False))
        task_state["phase"] = "service_starting"
    append_event(events_log, task_id, "start", str(cmd))
    proc = run_shell(str(cmd), task_state.get("node"), timeout=int(task_state.get("start_timeout_sec", 300)))
    task_state["start_returncode"] = proc.returncode
    task_state["start_output_tail"] = (proc.stdout + proc.stderr).strip()[-2000:]
    if proc.returncode != 0:
        task_state["status"] = "failed"
        task_state["result"] = "start_cmd 执行失败"
        task_state["finished_at"] = iso_ts()
        append_event(events_log, task_id, "failed", task_state["start_output_tail"])
        release_task(task_state, events_log, "start_cmd 执行失败")
        return
    task_state["status"] = "running"
    if task_state.get("eval_start_cmd"):
        task_state["progress"] = "服务启动命令已返回，等待模型服务 ready"
    append_event(events_log, task_id, "running", "start_cmd 返回 0，任务进入 running")


def read_remote_json(path, node):
    proc = run_shell("cat " + shlex.quote(path), node, timeout=30)
    if proc.returncode != 0 or not proc.stdout.strip():
        return None
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        return {"status": "error", "result": "status_file is not valid JSON", "raw": proc.stdout[-1000:]}


def service_status_file(task_state):
    return task_state.get("service_status_file") or task_state.get("llm_status_file")


def check_service_ready(task_state, events_log):
    task_id = get_task_id(task_state)
    path = service_status_file(task_state)
    if not path:
        return "ready"
    status = read_remote_json(str(path), task_state.get("node"))
    task_state["last_service_status"] = status
    task_state["last_check"] = iso_ts()
    if not status:
        task_state["phase"] = "service_starting"
        task_state["progress"] = "等待模型服务状态文件生成"
        return "wait"
    service_status = str(status.get("status") or "").lower()
    if service_status == "ready":
        if not task_state.get("service_ready_at"):
            task_state["service_ready_at"] = iso_ts()
            append_event(events_log, task_id, "service_ready", json.dumps(status, ensure_ascii=False)[-1000:])
        return "ready"
    if service_status in {"error", "timeout"}:
        task_state["status"] = "failed"
        task_state["phase"] = "service_failed"
        task_state["result"] = json.dumps(status, ensure_ascii=False)[-1000:]
        task_state["finished_at"] = iso_ts()
        append_event(events_log, task_id, "failed", "模型服务未 ready：" + task_state["result"])
        release_task(task_state, events_log, "模型服务未 ready")
        return "failed"
    task_state["phase"] = "service_starting"
    task_state["progress"] = status.get("message") or status.get("progress") or "等待模型服务 ready"
    return "wait"


def ensure_service_probe(task_state, events_log):
    task_id = get_task_id(task_state)
    if task_state.get("probe_checked"):
        return True
    task_state["phase"] = "probing"
    task_state["progress"] = "模型服务 ready，正在执行 curl 样本请求"
    result = run_service_probe(task_state)
    task_state["service_probe"] = result
    append_event(events_log, task_id, "service_probe", json.dumps(result, ensure_ascii=False)[-1000:])
    if result.get("status") == "ok":
        task_state["probe_checked"] = True
        task_state["probe_checked_at"] = iso_ts()
        task_state["progress"] = "curl 样本请求正常，准备执行评测"
        return True
    if result.get("status") == "garbled":
        task_state["status"] = "aborted"
        task_state["phase"] = "probe_garbled"
        task_state["result"] = result.get("detail", "curl 响应疑似乱码")
        task_state["finished_at"] = iso_ts()
        release_task(task_state, events_log, "curl 响应乱码")
        return False
    task_state["status"] = "failed"
    task_state["phase"] = "probe_failed"
    task_state["result"] = result.get("detail", "curl 请求失败")
    task_state["finished_at"] = iso_ts()
    release_task(task_state, events_log, "curl 请求失败")
    return False


def start_eval_if_needed(task_state, events_log):
    task_id = get_task_id(task_state)
    eval_cmd = task_state.get("eval_start_cmd")
    if not eval_cmd:
        return True
    if task_state.get("eval_started"):
        return True

    ready = check_service_ready(task_state, events_log)
    if ready != "ready":
        return False
    if not ensure_service_probe(task_state, events_log):
        return False

    task_state["phase"] = "evaluating"
    append_event(events_log, task_id, "eval_start", str(eval_cmd))
    proc = run_shell(str(eval_cmd), task_state.get("node"), timeout=int(task_state.get("eval_start_timeout_sec", 300)))
    task_state["eval_start_returncode"] = proc.returncode
    task_state["eval_start_output_tail"] = (proc.stdout + proc.stderr).strip()[-2000:]
    if proc.returncode != 0:
        task_state["status"] = "failed"
        task_state["result"] = "eval_start_cmd 执行失败"
        task_state["finished_at"] = iso_ts()
        append_event(events_log, task_id, "failed", task_state["eval_start_output_tail"])
        release_task(task_state, events_log, "eval_start_cmd 执行失败")
        return False
    task_state["eval_started"] = True
    task_state["eval_started_at"] = iso_ts()
    task_state["status"] = "running"
    task_state["progress"] = "评测已启动"
    append_event(events_log, task_id, "evaluating", "eval_start_cmd 返回 0，任务进入评测阶段")
    return True


def run_completion_check(task_state):
    cmd = task_state.get("completion_check_cmd")
    if cmd:
        proc = run_shell(str(cmd), task_state.get("node"), timeout=int(task_state.get("completion_timeout_sec", 60)))
        if proc.returncode == 0:
            return {
                "status": "done",
                "detail": (proc.stdout + proc.stderr).strip()[-1000:],
                "source": "completion_check_cmd",
            }

    done_file = task_state.get("done_file")
    if done_file:
        proc = run_shell("test -s " + shlex.quote(str(done_file)), task_state.get("node"), timeout=30)
        if proc.returncode == 0:
            return {"status": "done", "detail": str(done_file), "source": "done_file"}

    summary_glob = task_state.get("summary_glob")
    if summary_glob:
        proc = run_shell("ls -1 " + str(summary_glob) + " 2>/dev/null | tail -1", task_state.get("node"), timeout=30)
        if proc.returncode == 0 and proc.stdout.strip():
            return {
                "status": "done",
                "detail": proc.stdout.strip().splitlines()[-1],
                "source": "summary_glob",
            }

    return None


def mark_done(task_state, events_log, detail):
    task_id = get_task_id(task_state)
    task_state["status"] = "done"
    task_state["result"] = detail
    task_state["finished_at"] = task_state.get("finished_at") or iso_ts()
    append_event(events_log, task_id, "done", str(detail)[-1000:])
    if task_state.get("release_on_done", True):
        release_task(task_state, events_log, "任务完成")


def monitor_task(task_state, events_log):
    task_id = get_task_id(task_state)
    status_file = task_state.get("status_file")

    max_runtime = int(task_state.get("max_runtime_sec", 0) or 0)
    if max_runtime and task_state.get("started_at"):
        started = parse_iso_ts(task_state["started_at"])
        if (dt.datetime.now() - started).total_seconds() > max_runtime:
            task_state["status"] = "failed"
            task_state["result"] = f"任务超时，已运行超过 {max_runtime} 秒"
            task_state["finished_at"] = iso_ts()
            append_event(events_log, task_id, "failed", task_state["result"])
            release_task(task_state, events_log, "任务超时")
            return

    if task_state.get("eval_start_cmd"):
        if not start_eval_if_needed(task_state, events_log):
            return
    elif service_status_file(task_state) and not task_state.get("probe_checked"):
        ready = check_service_ready(task_state, events_log)
        if ready != "ready":
            return
        if not ensure_service_probe(task_state, events_log):
            return

    completion = run_completion_check(task_state)
    if completion and completion.get("status") == "done":
        mark_done(task_state, events_log, json.dumps(completion, ensure_ascii=False))
        return

    if not status_file:
        task_state["last_check"] = iso_ts()
        return
    status = read_remote_json(str(status_file), task_state.get("node"))
    if not status:
        return
    task_state["last_watcher_status"] = status
    task_state["last_check"] = iso_ts()
    watcher_status = str(status.get("status") or "").lower()
    if watcher_status == "done":
        mark_done(task_state, events_log, json.dumps(status, ensure_ascii=False)[-1000:])
    elif watcher_status == "aborted":
        task_state["status"] = "aborted"
        task_state["result"] = status.get("result", "")
        task_state["finished_at"] = iso_ts()
        append_event(events_log, task_id, "aborted", json.dumps(status, ensure_ascii=False)[-1000:])
        release_task(task_state, events_log, "watcher 标记 aborted")
    elif watcher_status == "error":
        task_state["status"] = "failed"
        task_state["result"] = status.get("result", "")
        task_state["finished_at"] = iso_ts()
        append_event(events_log, task_id, "failed", json.dumps(status, ensure_ascii=False)[-1000:])
        release_task(task_state, events_log, "watcher 标记 error")
    else:
        task_state["status"] = "running"
        task_state["progress"] = status.get("progress", "")


def task_datasets(task):
    for key in ("dataset", "datasets", "dataset_queue", "accuracy_datasets"):
        value = task.get(key)
        if not value:
            continue
        if isinstance(value, list):
            return ",".join(str(x) for x in value)
        return str(value)
    return ""


def display_status(task):
    status = str(task.get("status", ""))
    phase = task.get("phase")
    if phase and status in RUNNING:
        return status + "/" + str(phase)
    return status


def summarize_result(value):
    if not value:
        return ""
    if isinstance(value, dict):
        obj = value
    else:
        try:
            obj = json.loads(str(value))
        except Exception:
            return value
    if not isinstance(obj, dict):
        return value
    status = obj.get("status")
    source = obj.get("source")
    detail = obj.get("result") or obj.get("detail") or obj.get("progress") or ""
    if status:
        if source:
            return f"{status} ({source})"
        if detail:
            return f"{status}: {compact_text(detail, 80)}"
        return str(status)
    return detail or value


def task_result_text(task):
    if task.get("result"):
        return summarize_result(task.get("result"))
    probe = task.get("service_probe")
    if isinstance(probe, dict) and probe.get("status") == "ok" and task.get("status") in RUNNING:
        return "curl ok"
    return task.get("progress") or ""


def task_tool(task):
    for key in ("test_tool", "eval_tool", "accuracy_tool", "tool"):
        if task.get(key):
            return str(task[key])
    if task.get("opencompass_config") or task.get("work_dir") or task.get("summary_glob"):
        return "opencompass"
    return "evalscope"


def task_accelerator(task):
    for key in ("accelerator", "card_type", "target_card", "dcu_type", "gpu_type"):
        if task.get(key):
            return str(task[key])
    return ""


def plan_status_for_task(task):
    status = str(task.get("status") or "pending").lower()
    if status in {"done", "released"}:
        return PLAN_STATUS["done"]
    if status in {"failed", "aborted", "error", "timeout", "skipped"}:
        return PLAN_STATUS["failed"]
    if status in RUNNING:
        return PLAN_STATUS["running"]
    return PLAN_STATUS["pending"]


def sync_plan_status(task):
    new_status = plan_status_for_task(task)
    if task.get("plan_status") != new_status or not task.get("plan_timestamp"):
        task["plan_status"] = new_status
        task["plan_timestamp"] = now()


def write_task_plan(run_dir, state):
    reports = run_dir / "reports"
    reports.mkdir(parents=True, exist_ok=True)
    lines = [
        "# 任务计划表",
        "",
        "| 模型 | 测试工具 | 加速卡型号 | 状态 | 时间戳 |",
        "|---|---|---|---|---|",
    ]
    for _, task in sorted(state["tasks"].items()):
        sync_plan_status(task)
        lines.append(
            "| "
            + " | ".join(
                [
                    markdown_cell(task.get("model", ""), 64),
                    markdown_cell(task_tool(task), 32),
                    markdown_cell(task_accelerator(task), 32),
                    markdown_cell(task.get("plan_status", PLAN_STATUS["pending"]), 16),
                    markdown_cell(task.get("plan_timestamp", ""), 32),
                ]
            )
            + " |"
        )
    lines.append("")
    lines.append("状态只使用：待测试、测试中、通过、异常。")
    (reports / "task_plan.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_live_report(run_dir, state):
    reports = run_dir / "reports"
    reports.mkdir(parents=True, exist_ok=True)
    lines = [
        "# DCU LLM 测试报告",
        "",
        f"更新时间：{now()}",
        "",
        "| 任务ID | 模型 | 数据集 | 节点 | 状态 | 结果/进度 | 输出 |",
        "|---|---|---|---|---|---|---|",
    ]
    for task_id, task in sorted(state["tasks"].items()):
        lines.append(
            "| "
            + " | ".join(
                [
                    markdown_cell(task_id, 40),
                    markdown_cell(task.get("model", ""), 48),
                    markdown_cell(task_datasets(task), 48),
                    markdown_cell(task.get("node", ""), 32),
                    markdown_cell(display_status(task), 32),
                    markdown_cell(task_result_text(task), 120),
                    markdown_cell(task.get("output_dir", ""), 80),
                ]
            )
            + " |"
        )
    lines.append("")
    lines.append("说明：curl 样本检查在模型服务 ready 后执行；失败或乱码会释放该任务资源并继续后续任务。")
    content = "\n".join(lines) + "\n"
    (reports / "test_report.md").write_text(content, encoding="utf-8")
    (reports / "summary.md").write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", required=True)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--poll-interval", type=int, default=None)
    args = parser.parse_args()

    plan_path = Path(args.plan).resolve()
    run_dir = Path(args.run_dir).resolve()
    run_dir.mkdir(parents=True, exist_ok=True)
    state_path = run_dir / "state.json"
    events_log = run_dir / "events.log"

    plan = load_json(plan_path, {})
    tasks = plan.get("tasks", [])
    if not isinstance(tasks, list) or not tasks:
        raise SystemExit("plan.json must contain a non-empty tasks list")

    poll_interval = choose_poll_interval(args, plan)
    max_parallel_without_cards = int(plan.get("max_parallel_without_cards", 1))
    stop_on_failure = bool(plan.get("stop_on_failure", False))

    state = load_json(state_path, {"started_at": iso_ts(), "tasks": {}})
    state.setdefault("tasks", {})
    state["plan_path"] = str(plan_path)
    state["watch_interval_sec"] = poll_interval
    for task in tasks:
        task_id = get_task_id(task)
        if task_id not in state["tasks"]:
            merged = dict(task)
            merged["status"] = "pending"
            merged["probe_checked"] = bool(merged.get("probe_checked", False))
            if merged.get("eval_start_cmd"):
                merged["eval_started"] = bool(merged.get("eval_started", False))
            state["tasks"][task_id] = merged
        else:
            for key, value in task.items():
                state["tasks"][task_id].setdefault(key, value)
    write_task_plan(run_dir, state)
    atomic_write_json(state_path, state)
    write_live_report(run_dir, state)
    append_event(events_log, "-", "orchestrator_start", f"plan={plan_path}")

    final_report_written = False
    while True:
        state["updated_at"] = iso_ts()

        any_failure = False
        for task_id, task_state in list(state["tasks"].items()):
            if task_state.get("status") in RUNNING:
                monitor_task(task_state, events_log)
            if task_state.get("status") in {"failed", "aborted"}:
                any_failure = True

        if stop_on_failure and any_failure:
            for task_state in state["tasks"].values():
                if task_state.get("status") == "pending":
                    task_state["status"] = "skipped"
                    task_state["result"] = "由于 stop_on_failure=true，跳过后续任务"

        for task in sorted(tasks, key=task_sort_key):
            task_id = get_task_id(task)
            task_state = state["tasks"][task_id]
            if task_state.get("status") != "pending":
                continue
            if not resources_free(task_state, state["tasks"], max_parallel_without_cards):
                continue
            start_task(task_state, events_log)

        all_terminal = all(t.get("status") in TERMINAL for t in state["tasks"].values())
        state["all_terminal"] = all_terminal
        write_task_plan(run_dir, state)
        atomic_write_json(state_path, state)
        write_live_report(run_dir, state)
        if all_terminal:
            if not final_report_written:
                append_event(events_log, "-", "orchestrator_done", "所有任务均已进入终态")
                write_live_report(run_dir, state)
                final_report_written = True
            return 0
        time.sleep(poll_interval)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("已中断", file=sys.stderr)
        raise SystemExit(130)
