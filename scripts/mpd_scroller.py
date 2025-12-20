#!/usr/bin/env python3
import json, os, subprocess, hashlib
from pathlib import Path

WIDTH = 40       # ширина окна
STEP = 1         # шаг сдвига
STATE_FILE = Path("/tmp/mpd_scroller.json")

def run(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
    except:
        return ""

def get_status():
    out = run(["mpc", "status"])
    if not out:
        return "offline"
    if "[playing]" in out:
        return "playing"
    if "[paused]" in out:
        return "paused"
    return "stopped"

def get_track():
    t = run(["mpc", "-f", "%artist% - %title%", "current"])
    return t or run(["mpc", "current"])

def load_state():
    if STATE_FILE.exists():
        try: return json.loads(STATE_FILE.read_text())
        except: pass
    return {"track": "", "pos": 0, "dir": 1}

def save_state(s):
    STATE_FILE.write_text(json.dumps(s))

def bounce(track, s):
    n = len(track)
    if n <= WIDTH: return track
    pos, d = s["pos"], s["dir"]
    if pos < 0: pos, d = 0, 1
    if pos > n-WIDTH: pos, d = n-WIDTH, -1
    window = track[pos:pos+WIDTH]
    pos += STEP * d
    s["pos"], s["dir"] = pos, d
    return window

def main():
    st = get_status()
    track = get_track()
    state = load_state()
    if track: state["track"] = track
    track = state.get("track", "")
    if not track:
        print(json.dumps({"text": "MPD offline"}))
        return
    window = bounce(track, state)
    save_state(state)
    print(json.dumps({
        "text": window,
        "tooltip": track,
        "class": st,
        "alt": st
    }))

if __name__ == "__main__":
    main()
