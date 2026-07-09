# ptrace — view a Perfetto trace in the ui.perfetto.dev UI, two modes.
#
# HTTP mode (default for traces < $PTRACE_HTTP_MAX, ~1.8 GB):
#   Serves the trace *file* over a small HTTP server plus a tiny launcher page
#   that drives Perfetto's postMessage protocol: it window.open()s the UI,
#   fetches the trace from THIS same-origin server as an ArrayBuffer, and posts
#   it into the UI tab (PING/PONG handshake first). The browser parses it
#   client-side (WASM), caching it thereafter. The win: ONE server per root
#   serves every trace under that root, so N traces under a root = N tabs. The
#   server binds 0.0.0.0 and the URL points at this host by NAME ($(hostname),
#   override $PTRACE_HTTP_HOST), so the laptop browser reaches it directly over
#   the corp network — NO ssh tunnel, and NO "Relax CSP" flag (postMessage,
#   unlike the old ?url= deep link, needs neither CORS nor a CSP exception, and
#   sidesteps the mixed-content block of an HTTPS UI fetching an http:// trace).
#   The trace's root is whichever of `scratch_dir` / `workspace_dir` contains
#   it, and each root gets its own fixed port (base $PTRACE_HTTP_PORT, 9201) so
#   a scratch server and a workspace server coexist rather than fight over one
#   port. Re-running under the same root reuses its server; there's nothing to
#   swap or reap. The server is detached (setsid), so it persists past the
#   shell/ssh session that launched it — closing the terminal won't kill it; it
#   stays up until its idle watchdog fires.
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
#                          (both HTTP file servers and native RPC servers). Use
#                          after editing the server body, since a detached old
#                          server survives the shell and would be reused.
#
# One-time laptop browser setup: NATIVE mode needs the "Relax CSP for
# 127.0.0.1:*" flag and a YES on the "Trace Processor native acceleration"
# dialog (per browser profile). HTTP mode needs neither — just allow the popup
# if the browser blocks the first window.open (or click the launcher button).
#
# Env:
#   PTRACE_IDLE_TIMEOUT  inactivity before a server self-reaps (default 8h;
#                        "never" disables). Resets on UI activity. Both modes.
#   PTRACE_HTTP_MAX      auto-mode size cutoff in MB (default 1800).
#   PTRACE_HTTP_PORT     base port for HTTP-mode servers (default 9201; the
#                        second root uses +1).
#   PTRACE_HTTP_HOST     hostname the UI fetches HTTP-mode traces from (default
#                        $(hostname)) — set to an FQDN if the short name doesn't
#                        resolve from the laptop.
#   PTRACE_ROOT          override the HTTP-mode file-server root (sole candidate).
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
    # detached HTTP file server (matched by its PTRACE_HTTPD marker) and a
    # native trace_processor RPC server survive the launching shell, so after
    # editing the server body the old one lingers and `ptrace` reuses it — this
    # is the clean way to clear them without hunting PIDs.
    if (( kill_only )); then
        local killed=0
        if pgrep -f PTRACE_HTTPD >/dev/null 2>&1; then
            pkill -f PTRACE_HTTPD && killed=1
        fi
        if pgrep -f "trace_processor.*server http" >/dev/null 2>&1; then
            pkill -f "trace_processor.*server http" && killed=1
        fi
        if (( killed )); then
            print -P "%F{green}ptrace:%f killed ptrace-managed servers"
        else
            print -P "%F{green}ptrace:%f no ptrace-managed servers running"
        fi
        return 0
    fi

    local file="${1:-}"
    local port="${2:-9001}"
    local idle="${PTRACE_IDLE_TIMEOUT:-8h}"

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

# HTTP (client-side/WASM) mode: single CORS file server on 127.0.0.1:9001,
# rooted at the scratch/workspace dir containing the trace.
_ptrace_http() {
    local file="$1" idle="$2"

    if ! command -v python3 >/dev/null 2>&1; then
        print -u2 "ptrace: python3 not found (needed for HTTP mode) — use -n for native mode"
        return 1
    fi

    local abs=${file:A}

    # Candidate roots, in a STABLE order so each maps to a fixed port:
    #   scratch_dir -> $PTRACE_HTTP_PORT (9201), workspace_dir -> +1, ...
    # PTRACE_ROOT, if set, is the sole candidate on the base port. A per-root
    # port lets a scratch server and a workspace server coexist (each its own
    # tab + its own -L), instead of one server fighting over a single port.
    local base_port=${PTRACE_HTTP_PORT:-9201}
    local -a candidates
    if [[ -n ${PTRACE_ROOT:-} ]]; then
        candidates=("$PTRACE_ROOT")
    else
        candidates=("$(scratch_dir)" "$(workspace_dir)")
    fi

    # Pick the deepest candidate that is a path-prefix of the trace; its index
    # in the list fixes the port.
    local root="" c cabs
    integer i=0 idx=-1 best=-1
    for c in $candidates; do
        cabs=${c:A}
        if [[ $abs == $cabs || $abs == $cabs/* ]]; then
            if (( ${#cabs} > best )); then
                best=${#cabs}; root=$cabs; idx=$i
            fi
        fi
        (( i++ ))
    done
    if [[ -z $root ]]; then
        print -u2 "ptrace: trace is not under scratch_dir ($(scratch_dir)) or workspace_dir ($(workspace_dir))."
        print -u2 "        symlink it under one, set PTRACE_ROOT, or use native mode: ptrace -n $file"
        return 1
    fi
    integer port=$(( base_port + idx ))

    local rel=${abs#$root/}

    # HTTP mode ships the trace file across the wire, so a large uncompressed
    # JSON trace is slow to load. Perfetto sniffs the gzip magic and decompresses
    # client-side, so serve a gzipped copy when the trace isn't already
    # compressed — the transfer shrinks ~10x for JSON. Cache the .gz right next to
    # the original and reuse it while it's newer than its source. The size-based
    # mode cutoff in ptrace() already ran on the uncompressed size, so the
    # browser's ~2 GB WASM ceiling is still respected. Perfetto detects gzip by
    # magic bytes, not filename, so the .gz suffix on fileName is harmless.
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
    local serve_rel=${serve_abs#$root/}

    local enc
    enc=$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$serve_rel")

    local idle_secs
    idle_secs=$(_ptrace_secs "$idle")

    # Host the laptop browser fetches from. Defaults to this host's name (so no
    # ssh tunnel is needed — the browser reaches the work host directly on the
    # corp network); override with $PTRACE_HTTP_HOST (e.g. an FQDN).
    local http_host=${PTRACE_HTTP_HOST:-$(hostname)}

    # Is our server for THIS root already up on its port? Match the marker+root
    # in the process args (each server is launched as `... PTRACE_HTTPD <root> ...`).
    if pgrep -f "PTRACE_HTTPD $root " >/dev/null 2>&1; then
        print -P "%F{green}ptrace:%f reusing HTTP server on $http_host:$port (root %B$root%b)"
    else
        # Long-lived file server. argv: PTRACE_HTTPD <root> <port> <idle_secs>.
        # Binds 0.0.0.0 so the laptop browser can reach it by hostname (no
        # tunnel). Serves two things: (1) the raw trace files under <root>, and
        # (2) a tiny launcher page at /__ptrace_open__ that drives Perfetto's
        # postMessage protocol (window.open the UI, PING/PONG handshake, fetch
        # the trace as an ArrayBuffer from THIS same-origin server, post it in).
        # postMessage sidesteps the mixed-content wall the old ?url= deep link
        # hit: an HTTPS ui.perfetto.dev cannot fetch our http:// trace, but our
        # http:// page can, then hands the bytes over the window channel — so no
        # CSP flag and no CORS are needed. The CORS header is kept anyway (cheap,
        # and lets a manual ?url= still work). A watchdog thread self-reaps after
        # idle_secs of no GET (0 = never).
        local server_py='
import sys, os, time, threading
from http.server import HTTPServer, SimpleHTTPRequestHandler
root, port, idle = sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
os.chdir(root)
last = [time.time()]
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
var f = params.get("f") || "";
var title = params.get("title") || f;
document.getElementById("n").textContent = f;
function status(m){ document.getElementById("s").textContent = m; }
function openTrace(){
  var win = window.open(PERFETTO);
  if(!win){ status("Popup blocked. Allow popups for this page, then click the button above."); return; }
  status("Opening Perfetto and fetching trace...");
  var traceUrl = "/" + f.split("/").map(encodeURIComponent).join("/");
  fetch(traceUrl).then(function(r){
    if(!r.ok) throw new Error("fetch failed: " + r.status);
    return r.arrayBuffer();
  }).then(function(buf){
    status("Fetched " + Math.round(buf.byteLength/1048576) + " MB. Handshaking with Perfetto...");
    var done = false;
    var onMsg = function(e){
      if(e.data !== "PONG") return;
      done = true; clearInterval(ping);
      window.removeEventListener("message", onMsg);
      win.postMessage({perfetto:{buffer:buf, title:title, fileName:f.split("/").pop()}}, PERFETTO, [buf]);
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
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "https://ui.perfetto.dev")
        super().end_headers()
    def do_GET(self):
        last[0] = time.time()
        if self.path.split("?")[0] == "/__ptrace_open__":
            body = LAUNCHER.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()
    def log_message(self, *a): pass
httpd = HTTPServer(("0.0.0.0", port), H)
if idle > 0:
    def watchdog():
        while True:
            time.sleep(min(idle, 60))
            if time.time() - last[0] > idle: os._exit(0)
    threading.Thread(target=watchdog, daemon=True).start()
httpd.serve_forever()
'
        # Detach into its own session (setsid) with stdio fully closed, so the
        # server outlives the shell/ssh session that ran ptrace — closing the
        # terminal won't SIGHUP it. It stays up until its idle watchdog fires
        # (or it's killed). Fall back to a plain background job if setsid is
        # absent (disown then keeps it off this shell's job table).
        if command -v setsid >/dev/null 2>&1; then
            setsid python3 -c "$server_py" PTRACE_HTTPD "$root" "$port" "$idle_secs" \
                </dev/null >/dev/null 2>&1 &
        else
            python3 -c "$server_py" PTRACE_HTTPD "$root" "$port" "$idle_secs" \
                </dev/null >/dev/null 2>&1 &
        fi
        disown 2>/dev/null
        print -P "%F{green}ptrace:%f serving %B$root%b on $http_host:$port (idle-timeout $idle)"
    fi

    # Open our launcher page (same-origin fetch + postMessage into Perfetto),
    # not the ?url= deep link — the latter is mixed content (HTTPS UI fetching
    # our http:// trace) and is blocked by the browser.
    #
    # Title = the trace's basename, EXCEPT for generically-named traces
    # (chrometrace.json / sim_trace_final.json, gzipped or not) where the
    # filename carries no info and the PARENT DIRECTORY encodes what the trace
    # is — use that instead so tabs are distinguishable. Derive the parent from
    # the absolute path ($abs), not the root-relative $rel: they usually share a
    # parent, but if root IS the parent (e.g. PTRACE_ROOT set to the run dir)
    # $rel:h collapses to "." and the useful name is lost.
    local title=${abs:t}
    case ${title%.gz} in
        chrometrace.json|sim_trace_final.json)
            local parent=${abs:h:t}
            [[ -n $parent && $parent != / ]] && title=$parent
            ;;
    esac
    local title_enc
    title_enc=$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$title")
    local url="http://$http_host:$port/__ptrace_open__?f=${enc}&title=${title_enc}"
    print -P "  trace:       %B$rel%b"
    print -P "  then open:   %F{blue}$url%f"
    command -v browser-open >/dev/null 2>&1 && browser-open "$url" >/dev/null 2>&1 || true
}

# Native (RPC accelerator) mode: trace_processor server preloaded with the trace.
# One server = one trace = one port; re-running on a port swaps its trace.
_ptrace_native() {
    local file="$1" port="$2" idle="$3"

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
