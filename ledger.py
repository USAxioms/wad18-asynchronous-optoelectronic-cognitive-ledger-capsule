import hashlib, json, sys, os
P = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ledger", "ledger.jsonl")
def append(kind, payload):
    prev, seq = "0"*64, 0
    if os.path.exists(P):
        lines = [l for l in open(P) if l.strip()]
        if lines:
            last = json.loads(lines[-1]); prev, seq = last["hash"], last["seq"] + 1
    body = {"seq": seq, "prev": prev, "kind": kind, "payload": payload}
    h = hashlib.sha256(json.dumps(body, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    body["hash"] = h
    with open(P, "a") as f: f.write(json.dumps(body, sort_keys=True) + "\n")
    return h
def verify():
    prev = "0"*64
    for l in open(P):
        e = json.loads(l); h = e.pop("hash")
        assert e["prev"] == prev
        assert hashlib.sha256(json.dumps(e, sort_keys=True, separators=(",", ":")).encode()).hexdigest() == h
        prev = h
    return True
if __name__ == "__main__":
    if sys.argv[1] == "verify": print("LEDGER CHAIN OK" if verify() else "BAD")
    else: print(append(sys.argv[1], json.loads(sys.argv[2])))
