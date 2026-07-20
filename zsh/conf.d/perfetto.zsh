# ptrace — view a Perfetto trace in the ui.perfetto.dev UI, two modes.
#
# HTTP mode (default for traces < $PTRACE_HTTP_MAX, ~1.8 GB):
#   Serves the trace *file* over a small HTTP server plus a tiny launcher page
#   that drives Perfetto's postMessage protocol: it window.open()s the UI,
#   fetches the trace from THIS same-origin server as an ArrayBuffer, and posts
#   it into the UI tab (PING/PONG handshake first). The browser parses it
#   client-side (WASM), caching it thereafter. The server binds 0.0.0.0 and the
#   URL points at this host by NAME ($(hostname), override $PTRACE_HTTP_HOST), so
#   the laptop browser reaches it directly over the corp network — NO ssh tunnel,
#   and NO "Relax CSP" flag (postMessage, unlike the old ?url= deep link, needs
#   neither CORS nor a CSP exception, and sidesteps the mixed-content block of an
#   HTTPS UI fetching an http:// trace).
#
#   ONE per-user server on a FIXED port serves MANY traces by token. Each
#   invocation registers its trace in a local 0600 registry (token -> abspath)
#   and ensures the server is up on a fixed port (base $PTRACE_HTTP_PORT 9201 +
#   UID%50 — no probing, so opening two traces in quick succession CANNOT collide
#   on a port: the second just adds another token/tab on the SAME port; the
#   duplicate server it tries to launch exits on EADDRINUSE and the running one
#   picks up the new token). The server serves ONLY registered tokens at
#   /t/<token> (looked up by exact token, never by joining user input onto a dir,
#   so traversal is structurally impossible) plus the launcher — every other path
#   is 404, and only traces you explicitly `ptrace`'d are reachable. Each entry
#   is dropped (404 thereafter) ~$PTRACE_HTTP_GRACE (default 30s) after ITS fetch
#   delivers, so a file is on the wire only for its one click; the server itself
#   reaps when the registry is empty and idle ($PTRACE_IDLE_TIMEOUT, default 15m
#   for HTTP — much shorter than native's 8h). Reloading the *Perfetto* tab never
#   re-hits our server (buffer cached in-tab post-handshake); only re-opening the
#   launcher would, which the grace window covers. Users on a shared host land in
#   different UID bands, and registration is a local file the server polls — a
#   network party can fetch an allowlisted token but cannot add one.
#   Cost: the file crosses the wire, and the browser's ~2 GB memory ceiling
#   applies — hence the size cutoff to native mode. NOTE: window.open must ride
#   a user gesture, so if the browser blocks the auto-popup the launcher page
#   shows a button to click instead.
#
# Native mode (traces >= cutoff, or `ptrace -n`):
#   Runs trace_processor's HTTP RPC server with the trace preloaded; the UI
#   offloads all parsing to it and pulls back only rendered results, so the file
#   never leaves the host and there's no size limit. But it's one server = one
#   trace = one port, so viewing two traces needs two ports and two -L tunnels.
#   Re-running on the same port SWAPS the trace (reaps the old server). The UI
#   URL is version-pinned to the server build (…/vXX.Y-hash/…) so the RPC wire
#   protocol matches; an unpinned ui.perfetto.dev may have rolled ahead.
#
# Reaching the UI differs by mode: HTTP mode is fetched by hostname, so no tunnel
# and no browser flag (postMessage hands the bytes to the UI tab directly).
# NATIVE mode's RPC websocket only ever connects to 127.0.0.1:<port> ON THE
# LAPTOP (the CSP flag frees the port but not the host — binding 0.0.0.0 and
# browsing hostname:<port> shows the status page but will NOT load a trace), so
# it needs an `ssh -L <port>:localhost:<port>` forward (printed below).
#
# Mode selection:
#   ptrace <file> [port]   auto — HTTP if small, native if large (prints why)
#   ptrace -w <file>       force HTTP (web) mode        (also PTRACE_MODE=http)
#   ptrace -n <file> [port] force native mode           (also PTRACE_MODE=native)
#   ptrace -k              kill every ptrace-managed server on this host and stop
#                          (both HTTP and native RPC servers) and clear the HTTP
#                          registry. Use after editing the server body, since a
#                          detached old server survives the shell and is reused.
#
# One-time laptop browser setup: NATIVE mode needs the "Relax CSP for
# 127.0.0.1:*" flag and a YES on the "Trace Processor native acceleration"
# dialog (per browser profile). HTTP mode needs neither — just allow the popup
# if the browser blocks the first window.open (or click the launcher button).
#
# Env:
#   PTRACE_IDLE_TIMEOUT  inactivity before a server self-reaps. Default differs
#                        by mode: 15m for HTTP (server reaps once its registry is
#                        empty and idle), 8h for native. "never" disables.
#   PTRACE_HTTP_GRACE    HTTP mode: seconds after a trace is delivered before its
#                        registry entry is dropped (404 thereafter) — default 30;
#                        "never"/0 disables per-entry reap, leaving only idle.
#   PTRACE_HTTP_MAX      auto-mode size cutoff in MB (default 1800).
#   PTRACE_HTTP_PORT     base port for HTTP-mode servers (default 9201; the
#                        actual per-user port is base + UID%50, fixed — one
#                        server per user serves all their traces by token).
#   PTRACE_HTTP_HOST     hostname the UI fetches HTTP-mode traces from (default
#                        $(hostname)) — set to an FQDN if the short name doesn't
#                        resolve from the laptop.
#   PTRACE_MODE          "http" or "native" to set the default mode.

# Parse a duration (8h / 30m / 90s / 90 / never) to whole seconds; "never" -> 0.
_ptrace_secs() {
    local v=$1
    case $v in
        never|0) echo 0 ;;
        *h)      echo $(( ${v%h} * 3600 )) ;;
        *m)      echo $(( ${v%m} * 60 )) ;;
        *s)      echo ${v%s} ;;
        *)       echo $v ;;
    esac
}

ptrace() {
    emulate -L zsh
    setopt local_options

    # --- mode dispatch -----------------------------------------------------
    local mode=auto kill_only=0
    [[ ${PTRACE_MODE:-} == http   ]] && mode=http
    [[ ${PTRACE_MODE:-} == native ]] && mode=native
    while [[ ${1:-} == -* ]]; do
        case $1 in
            -w) mode=http;   shift ;;
            -n) mode=native; shift ;;
            -k) kill_only=1; shift ;;
            --) shift; break ;;
            *)  print -u2 "ptrace: unknown flag: $1"; return 2 ;;
        esac
    done

    # -k: reap every ptrace-managed server on this host and stop. Both a
    # detached HTTP server (matched by its PTRACE_HTTPD marker) and a native
    # trace_processor RPC server survive the launching shell, so after editing
    # the server body the old one lingers and `ptrace` reuses it — this is the
    # clean way to clear them without hunting PIDs. Also clears the HTTP
    # registry so no stale token entries survive the server they belonged to.
    if (( kill_only )); then
        local killed=0
        if pgrep -f PTRACE_HTTPD >/dev/null 2>&1; then
            pkill -f PTRACE_HTTPD && killed=1
        fi
        if pgrep -f "trace_processor.*server http" >/dev/null 2>&1; then
            pkill -f "trace_processor.*server http" && killed=1
        fi
        rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/ptrace/entries/"*.json(N) \
              "${XDG_CACHE_HOME:-$HOME/.cache}/ptrace/entries/"*.json.tmp(N) 2>/dev/null
        if (( killed )); then
            print -P "%F{green}ptrace:%f killed ptrace-managed servers"
        else
            print -P "%F{green}ptrace:%f no ptrace-managed servers running"
        fi
        return 0
    fi

    local file="${1:-}"
    local port="${2:-9001}"
    # Empty unless explicitly set, so each mode applies its own default (HTTP now
    # reaps on delivery, so it wants a short idle FALLBACK; native still wants 8h).
    local idle="${PTRACE_IDLE_TIMEOUT:-}"

    if [[ -z "$file" ]]; then
        print -u2 "usage: ptrace [-w|-n] <trace-file> [port]   |   ptrace -k  (kill all servers)"
        return 2
    fi
    if [[ ! -f "$file" ]]; then
        print -u2 "ptrace: no such file: $file"
        return 1
    fi

    # Auto: pick mode by file size (browser can't hold huge traces in WASM).
    if [[ $mode == auto ]]; then
        local max_mb=${PTRACE_HTTP_MAX:-1800}
        local size_b max_b
        size_b=$(stat -c %s "$file" 2>/dev/null || echo 0)
        max_b=$(( max_mb * 1024 * 1024 ))
        if (( size_b < max_b )); then
            mode=http
        else
            mode=native
            print -P "%F{yellow}ptrace:%f $(( size_b / 1024 / 1024 ))MB ≥ ${max_mb}MB cutoff — using native mode (browser can't hold it). Override with -w."
        fi
    fi

    if [[ $mode == http ]]; then
        _ptrace_http "$file" "$idle"
    else
        _ptrace_native "$file" "$port" "$idle"
    fi
}

# HTTP (client-side/WASM) mode: ONE per-user server on a FIXED port, serving
# MANY traces by token.
#
# Each `ptrace` registers its trace in a local 0600 registry (a token -> abspath
# entry file) and ensures the per-user server is up on a FIXED port (base +
# UID%50 — no probing, so opening two traces in quick succession can't collide:
# the second just adds another token/tab on the SAME port). The server polls the
# registry and serves ONLY registered tokens at /t/<token> (plus the launcher at
# /__ptrace_open__) — every other path is 404, and paths are looked up by exact
# token, never by joining user input onto a dir, so traversal is structurally
# impossible and only traces you explicitly `ptrace`'d are reachable. Each entry
# is dropped (404 thereafter) ~$PTRACE_HTTP_GRACE (default 30s) after ITS fetch
# delivers, so a file is on the wire only for its one click; the server itself
# reaps when the registry is empty and idle ($PTRACE_IDLE_TIMEOUT, default 15m).
# It binds 0.0.0.0 and is reached by hostname (no ssh tunnel), preserving the
# shareable story. Registration is a local file the server polls — a network
# party can fetch an allowlisted token but cannot add one.
_ptrace_http() {
    local file="$1" idle="${2:-15m}"

    if ! command -v python3 >/dev/null 2>&1; then
        print -u2 "ptrace: python3 not found (needed for HTTP mode) — use -n for native mode"
        return 1
    fi

    local abs=${file:A}

    # HTTP mode ships the trace file across the wire, so a large uncompressed
    # JSON trace is slow to load. Perfetto sniffs the gzip magic and decompresses
    # client-side, so serve a gzipped copy when the trace isn't already
    # compressed — the transfer shrinks ~10x for JSON. Cache the .gz right next to
    # the original and reuse it while it's newer than its source. The size-based
    # mode cutoff in ptrace() already ran on the uncompressed size, so the
    # browser's ~2 GB WASM ceiling is still respected. Perfetto detects gzip by
    # magic bytes, not filename, so serving it with a neutral content-type (no
    # Content-Encoding) is correct — the browser hands the raw gzip to the WASM.
    local serve_abs=$abs
    if [[ ${abs:l} != *.gz ]]; then
        local gz=$abs.gz
        if [[ -f $gz && $gz -nt $abs ]]; then
            serve_abs=$gz
        elif command -v gzip >/dev/null 2>&1; then
            print -P "%F{green}ptrace:%f gzipping trace for faster transfer (one-time)…"
            if gzip -c "$abs" > "$gz.tmp" 2>/dev/null && mv -f "$gz.tmp" "$gz"; then
                serve_abs=$gz
            else
                rm -f "$gz.tmp"
                print -u2 "ptrace: gzip failed — serving uncompressed"
            fi
        fi
    fi

    local idle_secs grace_secs
    idle_secs=$(_ptrace_secs "$idle")
    grace_secs=$(_ptrace_secs "${PTRACE_HTTP_GRACE:-30}")

    # Fixed per-user port (base + UID%50): users on a shared host land in
    # different bands, and a single user's repeated opens all reuse the SAME
    # port/server — so rapid successive traces never fight over a port.
    local base_port=${PTRACE_HTTP_PORT:-9201}
    integer uid=$(id -u)
    integer port=$(( base_port + uid % 50 ))

    # Per-user registry: a private dir of token->trace entry files the server
    # polls. 0700 so no other user can read your trace paths or inject a token.
    local reg="${XDG_CACHE_HOME:-$HOME/.cache}/ptrace"
    mkdir -p "$reg/entries" 2>/dev/null
    chmod 700 "$reg" "$reg/entries" 2>/dev/null

    # Title = the trace's basename, EXCEPT for generically-named traces
    # (chrometrace.json / sim_trace_final.json, gzipped or not) where the
    # filename carries no info and the PARENT DIRECTORY encodes what the trace is.
    local title=${abs:t}
    case ${title%.gz} in
        chrometrace.json|sim_trace_final.json)
            local parent=${abs:h:t}
            [[ -n $parent && $parent != / ]] && title=$parent
            ;;
    esac

    # Register this trace and get its token (atomic write: tmp then rename, so the
    # polling server never reads a half-written entry). "name" is the fileName
    # shown in Perfetto (the original, un-gzipped basename).
    local reg_py='
import sys, os, json, time, secrets
ed, path, title, name = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
tok = secrets.token_urlsafe(9)
rec = {"path": os.path.abspath(path), "title": title, "name": name, "added": time.time()}
tmp = os.path.join(ed, tok + ".json.tmp"); fin = os.path.join(ed, tok + ".json")
with open(tmp, "w") as f: f.write(json.dumps(rec))
os.chmod(tmp, 0o600); os.replace(tmp, fin)
print(tok)
'
    local token
    token=$(python3 -c "$reg_py" "$reg/entries" "$serve_abs" "$title" "${abs:t}") || {
        print -u2 "ptrace: failed to register trace"; return 1
    }

    local http_host=${PTRACE_HTTP_HOST:-$(hostname)}

    # Server. argv: PTRACE_HTTPD <reg> <port> <idle> <grace>. Polls <reg>/entries
    # once a second: adds new tokens to the allowlist, drops entries whose files
    # were removed, and reaps per-entry (delivered + grace, or never-fetched +
    # idle). Serves /t/<token> (streamed from the entry's abspath) and the
    # /__ptrace_open__ launcher; everything else 404. The launcher drives
    # Perfetto's postMessage protocol (window.open the UI, PING/PONG handshake,
    # fetch /t/<token> as an ArrayBuffer from THIS same-origin server, post it in)
    # — sidestepping the mixed-content wall an HTTPS UI hits fetching an http://
    # trace, so no CSP flag and no CORS. On startup it tries to bind the fixed
    # port; if another of our servers already holds it (EADDRINUSE) it exits — the
    # running one will pick up our just-registered token. Self-reaps when the
    # allowlist is empty and idle.
    local server_py='
import sys, os, time, json, glob, shutil, threading
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import unquote, parse_qs, urlsplit
reg, port, idle, grace = sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
ed = os.path.join(reg, "entries")
os.makedirs(ed, exist_ok=True)
allow = {}          # token -> record (with mutable "delivered")
last = [time.time()]
def scan():
    seen = set()
    for fp in glob.glob(os.path.join(ed, "*.json")):
        tok = os.path.basename(fp)[:-5]; seen.add(tok)
        if tok not in allow:
            try: rec = json.load(open(fp))
            except Exception: continue
            rec["delivered"] = None; allow[tok] = rec
    for tok in list(allow):
        if tok not in seen: allow.pop(tok, None)
def reap():
    now = time.time()
    for tok, rec in list(allow.items()):
        d = rec.get("delivered")
        expired = (d and grace > 0 and now - d > grace) or \
                  (not d and idle > 0 and now - rec.get("added", now) > idle)
        if expired:
            try: os.remove(os.path.join(ed, tok + ".json"))
            except OSError: pass
            allow.pop(tok, None)
def maintain():
    while True:
        time.sleep(1); scan(); reap()
        if not allow and idle > 0 and time.time() - last[0] > idle: os._exit(0)
LAUNCHER = """<!doctype html>
<html><head><meta charset="utf-8"><title>ptrace to Perfetto</title>
<style>
body{font-family:sans-serif;max-width:40rem;margin:3rem auto;padding:0 1rem}
button{font-size:1rem;padding:.6rem 1rem;cursor:pointer}
#s{margin-top:1rem;color:#555;white-space:pre-wrap}
code{background:#f0f0f0;padding:.1rem .3rem;border-radius:3px}
</style></head><body>
<h2>ptrace to Perfetto</h2>
<p>Trace: <code id="n"></code></p>
<button id="go">Open in Perfetto UI</button>
<div id="s"></div>
<script>
var PERFETTO = "https://ui.perfetto.dev";
var params = new URLSearchParams(location.search);
var tok = params.get("t") || "";
var title = params.get("title") || tok;
var name = params.get("n") || title;
document.getElementById("n").textContent = title;
function status(m){ document.getElementById("s").textContent = m; }
function openTrace(){
  var win = window.open(PERFETTO);
  if(!win){ status("Popup blocked. Allow popups for this page, then click the button above."); return; }
  status("Opening Perfetto and fetching trace...");
  fetch("/t/" + encodeURIComponent(tok)).then(function(r){
    if(!r.ok) throw new Error("fetch failed: " + r.status + " (trace may have expired — re-run ptrace)");
    return r.arrayBuffer();
  }).then(function(buf){
    status("Fetched " + Math.round(buf.byteLength/1048576) + " MB. Handshaking with Perfetto...");
    var done = false;
    var onMsg = function(e){
      if(e.data !== "PONG") return;
      done = true; clearInterval(ping);
      window.removeEventListener("message", onMsg);
      win.postMessage({perfetto:{buffer:buf, title:title, fileName:name}}, PERFETTO, [buf]);
      status("Trace sent to Perfetto. Closing this tab...");
      // Auto-close once the data is handed off. Browsers only honor close() on
      // script-opened tabs, so this may be blocked when the launcher was opened
      // externally (lemonade) — fall back to a manual-close hint if so.
      setTimeout(function(){
        window.close();
        status("Trace sent to Perfetto. You can close this tab.");
      }, 800);
    };
    window.addEventListener("message", onMsg);
    var ping = setInterval(function(){ if(!done) win.postMessage("PING", PERFETTO); }, 50);
    setTimeout(function(){ if(!done){ clearInterval(ping); status("Perfetto did not respond (handshake timed out). Is the tab open and unblocked?"); } }, 20000);
  }).catch(function(e){ status("Error: " + e.message); });
}
document.getElementById("go").addEventListener("click", openTrace);
openTrace();
</script></body></html>
"""
class H(SimpleHTTPRequestHandler):
    def _send_html(self, body):
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers(); self.wfile.write(body)
    def do_GET(self):
        last[0] = time.time()
        path = unquote(urlsplit(self.path).path)
        if path == "/__ptrace_open__":
            self._send_html(LAUNCHER.encode("utf-8")); return
        if path.startswith("/t/"):
            rec = allow.get(path[3:])
            if not rec: self.send_error(404); return
            try:
                f = open(rec["path"], "rb"); sz = os.fstat(f.fileno()).st_size
            except OSError:
                self.send_error(404); return
            self.send_response(200)
            self.send_header("Access-Control-Allow-Origin", "https://ui.perfetto.dev")
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(sz))
            self.end_headers()
            try: shutil.copyfileobj(f, self.wfile)
            finally: f.close()
            rec["delivered"] = time.time()   # full body written -> delivered
            return
        self.send_error(404)
    def log_message(self, *a): pass
scan()
try:
    httpd = HTTPServer(("0.0.0.0", port), H)
except OSError:
    os._exit(0)   # another of our servers already holds the port; it will serve us
threading.Thread(target=maintain, daemon=True).start()
httpd.serve_forever()
'
    # Is our server already up on this port? (matched by marker+reg in argv).
    if pgrep -f "PTRACE_HTTPD $reg $port" >/dev/null 2>&1; then
        print -P "%F{green}ptrace:%f added to running server on $http_host:$port (reaps ~${grace_secs}s after open)"
    else
        # Detach into its own session (setsid), stdio closed, so the server
        # outlives the shell/ssh session — closing the terminal won't SIGHUP it.
        # It self-reaps when idle+empty; `ptrace -k` clears it and the registry.
        # (A duplicate launch from a racing shell just exits on EADDRINUSE.)
        if command -v setsid >/dev/null 2>&1; then
            setsid python3 -c "$server_py" PTRACE_HTTPD "$reg" "$port" "$idle_secs" "$grace_secs" \
                </dev/null >/dev/null 2>&1 &
        else
            python3 -c "$server_py" PTRACE_HTTPD "$reg" "$port" "$idle_secs" "$grace_secs" \
                </dev/null >/dev/null 2>&1 &
        fi
        disown 2>/dev/null
        print -P "%F{green}ptrace:%f serving on $http_host:$port (per-user; reaps ~${grace_secs}s after open, idle $idle)"
    fi

    # Open our launcher page (same-origin fetch + postMessage into Perfetto), not
    # the ?url= deep link — the latter is mixed content (HTTPS UI fetching our
    # http:// trace) and is blocked by the browser.
    local title_enc name_enc
    title_enc=$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$title")
    name_enc=$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "${abs:t}")
    local url="http://$http_host:$port/__ptrace_open__?t=${token}&title=${title_enc}&n=${name_enc}"
    print -P "  trace:       %B$abs%b"
    print -P "  then open:   %F{blue}$url%f"
    command -v browser-open >/dev/null 2>&1 && browser-open "$url" >/dev/null 2>&1 || true
}

# Native (RPC accelerator) mode: trace_processor server preloaded with the trace.
# One server = one trace = one port; re-running on a port swaps its trace.
_ptrace_native() {
    local file="$1" port="$2" idle="${3:-8h}"

    if ! command -v trace_processor >/dev/null 2>&1; then
        print -u2 "ptrace: trace_processor not found — run ./install.sh perfetto"
        return 1
    fi

    # Swap traces cleanly: reap any server we previously started on this port.
    # The wrapper execs the real binary as trace_processor_shell-<hash>, so the
    # pattern must span that suffix (a bare "trace_processor server" misses it).
    pkill -f "trace_processor.*server http.*--port $port" 2>/dev/null && sleep 1

    # Bind default 127.0.0.1 (the -L tunnel rides loopback); self-reap when idle.
    trace_processor server http --port "$port" --idle-timeout "$idle" "$file" \
        >/dev/null 2>&1 &
    disown

    # Pin the UI to the server build so the wire protocol matches (see header).
    local ver
    ver=$(trace_processor --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+-[0-9a-f]+' | head -1)
    local url="https://ui.perfetto.dev/${ver:+$ver/}#!?rpc_port=$port"

    print -P "%F{green}ptrace:%f serving %B$file%b on 127.0.0.1:$port (native, idle-timeout $idle)"
    print -P "  laptop ssh:  %F{yellow}ssh -L ${port}:localhost:${port} $HOST%f  (if not already forwarded)"
    print -P "  then open:   %F{blue}$url%f"

    # Best-effort auto-open via $BROWSER (browser-open → lemonade). You'll still
    # need to reload/confirm the native-acceleration dialog manually.
    command -v browser-open >/dev/null 2>&1 && browser-open "$url" >/dev/null 2>&1 || true
}
