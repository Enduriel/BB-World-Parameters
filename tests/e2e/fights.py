# fights.py <run.log>: world-map fight outcomes from a world_fights log (copied from the modern-engine diagnosis, scratch-targets/world-parameters/tools).
import re, sys, collections
P = re.compile(r"\[#(\d+) '([^']*)' f(\d+) troops (\d+) str ([\d.]+) cid (\d+)( DEAD)?\]|\[#(\d+) gone\]")
first, ends = {}, {}
for line in open(sys.argv[1], errors="replace"):
    m = re.search(r"first tick combat (\d+) lists (\d+)[^:]*:(.*)", line)
    if m:
        cid = int(m.group(1)); parties = {}
        for p in P.finditer(m.group(3)):
            if p.group(1): parties[int(p.group(1))] = (p.group(2), int(p.group(3)), int(p.group(4)), float(p.group(5)))
        first[cid] = parties
        continue
    m = re.search(r"end combat (\d+) \(from day \d+\):(.*)", line)
    if m:
        alive = set()
        for p in P.finditer(m.group(2)):
            if p.group(1) and not p.group(7) and int(p.group(4)) > 0: alive.add(int(p.group(1)))
        ends[int(m.group(1))] = alive
stats = collections.Counter(); examples = collections.defaultdict(list)
for cid, parties in first.items():
    if cid not in ends: stats["unfinished"] += 1; continue
    alive = ends[cid]
    side = collections.defaultdict(float)
    for pid, (n, f, t, s) in parties.items(): side[f] += s
    if len(side) < 2: stats["one-faction"] += 1; continue
    hi = any(f >= 32 for f in side)
    key = "high-id involved" if hi else "all ids < 32"
    stats[key] += 1
    if not alive:
        stats[key + ": nobody survived"] += 1; examples[key + ": nobody survived"].append((cid, parties)); continue
    winners = {parties[p][1] for p in alive if p in parties}
    strongest = max(side, key=side.get)
    if strongest not in winners:
        stats[key + ": weaker side won"] += 1; examples[key + ": weaker side won"].append((cid, parties, alive))
for k in sorted(stats): print(f"{k}: {stats[k]}")
for k, ex in examples.items():
    print("==", k)
    for e in ex[:6]:
        print("  combat", e[0], {pid: v for pid, v in e[1].items()}, "survivors", e[2] if len(e) > 2 else "none")
