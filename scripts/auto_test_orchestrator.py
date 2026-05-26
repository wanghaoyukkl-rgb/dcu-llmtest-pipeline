#!/usr/bin/env python3
"""DCU LLM 长队列测试后台编排器。

这个脚本用于执行已经确认的多模型/多波次测试计划，适合跨小时或跨天运行。
它运行在后台，不依赖 Codex/Agent 会话保持在线。

设计原则偏保守：
- 读取用户确认后的 plan.json。
- 仅在节点和卡资源空闲时启动 pending 任务。
- 持续读取每个任务 watcher 写出的状态 JSON，或 OpenCompass 输出目录中的 summary 文件。
- 遇到 error/aborted/timeout/prediction 乱码时记录失败，释放当前任务资源，
  然后继续调度后续 pending 任务。

典型用法：
  nohup python3 auto_test_orchestrator.py --plan <run_dir>/plan.json --run-dir <run_dir> \
    > <run_dir>/orchestrator.log 2>&1 &

主要输出：
- state.json：当前任务状态，可用于恢复和查询。
- events.log：任务启动、完成、失败、释放资源等事件流水。
- reports/summary.md：所有任务进入终态后的汇总草稿。
"""

import argparse
import datetime as dt
import json
import os
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


TERMINAL = {"done", "failed", "aborted", "released", "skipped"}
RUNNING = {"starting", "running"}


DETECTOR_CODE = r'''
import json
import os
import re
import sys

root = sys.argv[1] if len(sys.argv) > 1 else "auto"

def resolve(path):
    if not path or path == "auto":
        candidates = []
        for base in ("/tmp", "/workspace", "/mnt"):
            if not os.path.isdir(base):
                continue
            for dirpath, _, filenames in os.walk(base):
                for name in filenames:
                    lname = name.lower()
                    if "pred" in lname or lname.endswith(".jsonl") or lname.endswith(".json"):
                        full = os.path.join(dirpath, name)
                        try:
                            candidates.append((os.path.getmtime(full), full))
                        except OSError:
                            pass
        return max(candidates)[1] if candidates else ""
    if os.path.isdir(path):
        candidates = []
        for dirpath, _, filenames in os.walk(path):
            for name in filenames:
                lname = name.lower()
                if "pred" in lname or lname.endswith(".jsonl") or lname.endswith(".json"):
                    full = os.path.join(dirpath, name)
                    try:
                        candidates.append((os.path.getmtime(full), full))
                    except OSError:
                        pass
        return max(candidates)[1] if candidates else ""
    return path if os.path.isfile(path) else ""

def extract_text(obj):
    if isinstance(obj, str):
        return obj
    if not isinstance(obj, dict):
        return ""
    for key in ("prediction", "pred", "response", "output", "text", "generated_text", "completion"):
        val = obj.get(key)
        if isinstance(val, str):
            return val
        if isinstance(val, list):
            return " ".join(str(x) for x in val)
    choices = obj.get("choices")
    if isinstance(choices, list) and choices:
        return extract_text(choices[0])
    return ""

def garbled(text):
    s = str(text).strip()
    if not s:
        return False
    if "\ufffd" in s or "\\ufffd" in s:
        return True
    if re.search(r"([\W_])\1{7,}", s):
        return True
    if len(s) >= 12:
        useful = sum(ch.isalnum() or "\u4e00" <= ch <= "\u9fff" or ch in " .,;:!?+-=*/()[]{}<>%$#@'\"\n\t" for ch in s)
        return useful / max(len(s), 1) < 0.35
    return False

file_path = resolve(root)
if not file_path:
    print(json.dumps({"status": "wait", "detail": "NO_PREDICTION_FILE"}, ensure_ascii=False))
    raise SystemExit(0)

checked = 0
bad = 0
with open(file_path, "r", encoding="utf-8", errors="replace") as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except Exception:
            obj = line
        text = extract_text(obj)
        if not text:
            continue
        checked += 1
        if garbled(text):
            bad += 1
        if checked >= 3:
            break

if checked < 3:
    print(json.dumps({"status": "wait", "file": file_path, "detail": f"仅找到 {checked} 条样本"}, ensure_ascii=False))
elif bad == 3:
    print(json.dumps({"status": "garbled", "file": file_path, "detail": "前 3 条 prediction 均疑似乱码"}, ensure_ascii=False))
else:
    print(json.dumps({"status": "ok", "file": file_path, "checked": checked, "garbled": bad}, ensure_ascii=False))
'''


def now() -> str:
    return dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def iso_ts() -> str:
    return dt.datetime.now().isoformat(timespec="seconds")


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
    task_state["prediction_checked"] = bool(task_state.get("prediction_checked", False))
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
    append_event(events_log, task_id, "running", "start_cmd 返回 0，任务进入 running")


def read_remote_json(path, node):
    proc = run_shell("cat " + shlex.quote(path), node, timeout=30)
    if proc.returncode != 0 or not proc.stdout.strip():
        return None
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        return {"status": "error", "result": "status_file is not valid JSON", "raw": proc.stdout[-1000:]}


def run_prediction_check(task_state):
    prediction_path = str(task_state.get("prediction_path") or "")
    if not prediction_path:
        return {"status": "skip", "detail": "未配置 prediction_path"}
    code = shlex.quote(DETECTOR_CODE)
    path = shlex.quote(prediction_path)
    container = task_state.get("container")
    if container and task_state.get("prediction_in_container", True):
        cmd = "docker exec " + shlex.quote(str(container)) + " python3 -c " + code + " " + path
    else:
        cmd = "python3 -c " + code + " " + path
    proc = run_shell(cmd, task_state.get("node"), timeout=120)
    if proc.returncode != 0:
        return {"status": "wait", "detail": (proc.stdout + proc.stderr).strip()[-1000:]}
    try:
        return json.loads(proc.stdout.strip().splitlines()[-1])
    except Exception:
        return {"status": "wait", "detail": proc.stdout.strip()[-1000:]}


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


def monitor_task(task_state, events_log, default_prediction_delay):
    task_id = get_task_id(task_state)
    status_file = task_state.get("status_file")

    max_runtime = int(task_state.get("max_runtime_sec", 0) or 0)
    if max_runtime and task_state.get("started_at"):
        started = dt.datetime.fromisoformat(str(task_state["started_at"]))
        if (dt.datetime.now() - started).total_seconds() > max_runtime:
            task_state["status"] = "failed"
            task_state["result"] = f"任务超时，已运行超过 {max_runtime} 秒"
            task_state["finished_at"] = iso_ts()
            append_event(events_log, task_id, "failed", task_state["result"])
            release_task(task_state, events_log, "任务超时")
            return

    if (
        not task_state.get("prediction_checked")
        and task_state.get("prediction_path")
        and task_state.get("started_at")
    ):
        delay = int(task_state.get("prediction_check_after_sec", default_prediction_delay) or default_prediction_delay)
        started = dt.datetime.fromisoformat(str(task_state["started_at"]))
        if (dt.datetime.now() - started).total_seconds() >= delay:
            check = run_prediction_check(task_state)
            task_state["prediction_check"] = check
            if check.get("status") in {"ok", "garbled", "skip"}:
                task_state["prediction_checked"] = True
            append_event(events_log, task_id, "prediction_check", json.dumps(check, ensure_ascii=False))
            if check.get("status") == "garbled":
                task_state["status"] = "aborted"
                task_state["result"] = "前 3 条 prediction 均疑似乱码"
                task_state["finished_at"] = iso_ts()
                release_task(task_state, events_log, "prediction 乱码")
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


def write_final_report(run_dir, state):
    reports = run_dir / "reports"
    reports.mkdir(parents=True, exist_ok=True)
    lines = ["# 自动测试汇总", "", f"生成时间：{now()}", ""]
    for task_id, task in sorted(state["tasks"].items()):
        lines.append(f"## {task_id}")
        lines.append("")
        lines.append(f"- 模型：{task.get('model', '')}")
        lines.append(f"- 节点：{task.get('node', '')}")
        lines.append(f"- 卡 ID：{task.get('cards', '')}")
        lines.append(f"- 状态：{task.get('status', '')}")
        if task.get("result"):
            lines.append(f"- 结果/错误：{task.get('result')}")
        if task.get("output_dir"):
            lines.append(f"- 输出目录：{task.get('output_dir')}")
        if task.get("release_status"):
            lines.append(f"- 资源释放状态：{task.get('release_status')}")
        lines.append("")
    (reports / "summary.md").write_text("\n".join(lines), encoding="utf-8")


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

    poll_interval = args.poll_interval or int(plan.get("poll_interval_sec", 120))
    default_prediction_delay = int(plan.get("default_prediction_check_after_sec", 600))
    max_parallel_without_cards = int(plan.get("max_parallel_without_cards", 1))
    stop_on_failure = bool(plan.get("stop_on_failure", False))

    state = load_json(state_path, {"started_at": iso_ts(), "tasks": {}})
    state.setdefault("tasks", {})
    state["plan_path"] = str(plan_path)
    for task in tasks:
        task_id = get_task_id(task)
        if task_id not in state["tasks"]:
            merged = dict(task)
            merged["status"] = "pending"
            merged["prediction_checked"] = False
            state["tasks"][task_id] = merged
        else:
            for key, value in task.items():
                state["tasks"][task_id].setdefault(key, value)
    atomic_write_json(state_path, state)
    append_event(events_log, "-", "orchestrator_start", f"plan={plan_path}")

    final_report_written = False
    while True:
        state["updated_at"] = iso_ts()

        any_failure = False
        for task_id, task_state in list(state["tasks"].items()):
            if task_state.get("status") in RUNNING:
                monitor_task(task_state, events_log, default_prediction_delay)
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
        atomic_write_json(state_path, state)
        if all_terminal:
            if not final_report_written:
                write_final_report(run_dir, state)
                append_event(events_log, "-", "orchestrator_done", "所有任务均已进入终态")
                final_report_written = True
            return 0
        time.sleep(poll_interval)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("已中断", file=sys.stderr)
        raise SystemExit(130)
