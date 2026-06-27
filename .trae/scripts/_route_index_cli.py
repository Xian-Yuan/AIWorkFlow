"""Route index CLI driver — used by jinli-route-index.ps1."""
import json
import sys
from pathlib import Path

ws = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(ws))
action = sys.argv[2] if len(sys.argv) > 2 else "show"

from Project.Jinli.services.runtime.route_index import (
    build_route_index,
    check_route_index,
    default_index_path,
    write_route_index,
)

ip = default_index_path(ws)

if action == "build":
    idx = build_route_index(ws)
    write_route_index(idx, ip)
    print(json.dumps({
        "action": "build",
        "path": str(ip),
        "digest": idx["digest"],
        "file_routes": len(idx["file_routes"]),
        "workflow_routes": len(idx["workflow_routes"]),
    }, ensure_ascii=False))
    sys.exit(0)
elif action == "check":
    ok, problems = check_route_index(ws, ip)
    print(json.dumps({"action": "check", "ok": ok, "problems": problems}, ensure_ascii=False))
    sys.exit(0 if ok else 1)
elif action == "show":
    if not ip.exists():
        print(json.dumps({"action": "show", "error": f"missing: {ip}"}, ensure_ascii=False))
        sys.exit(1)
    idx = json.loads(ip.read_text(encoding="utf-8"))
    print(json.dumps({
        "action": "show",
        "generated_at": idx.get("generated_at"),
        "digest": idx.get("digest"),
        "file_routes": [
            {"key": e["key"], "count": e["count"]}
            for e in idx.get("file_routes", [])
        ],
        "workflow_routes": [
            {"key": e["key"], "mode": e["mode"], "request_type": e["request_type"]}
            for e in idx.get("workflow_routes", [])
        ],
    }, ensure_ascii=False))
    sys.exit(0)
else:
    print(json.dumps({"action": "?", "error": f"unknown action: {action}"}, ensure_ascii=False))
    sys.exit(2)
