import subprocess, shutil, os, sys
R = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
M = [("rtl/y18_math.sv","{a[W-1], a} + {b[W-1], b}","{a[W-1], a} - {b[W-1], b}"),
 ("rtl/y18_math.sv","(s_ext[W] != s_ext[W-1])","(s_ext[W] == s_ext[W-1])"),
 ("rtl/y18_math.sv","256'sd1000000000000000000","256'sd999999999999999999"),
 ("rtl/y18_math.sv","!= {(W+1){1'b1}}","!= {(W+1){1'b0}}"),
 ("rtl/y18_axiom_eval.sv","(acc > LIMIT)","(acc >= LIMIT)"),
 ("rtl/y18_axiom_eval.sv","> SMAX",">= SMAX"),
 ("rtl/y18_axiom_eval.sv","< SMIN","<= SMIN"),
 ("rtl/y18_axiom_eval.sv","!in_valid","in_valid"),
 ("rtl/y18_axiom_eval.sv","| oa1 |","| "),
 ("rtl/y18_axiom_eval.sv","(|ovm)","1'b0"),
 ("rtl/asc_top.sv","latched | viol;","viol;"),
 ("rtl/asc_top.sv","else if (viol) latched <= 1'b1;","else latched <= 1'b0;")]
def run(root):
    c = subprocess.run(["iverilog","-g2012","-o",root+"/sim.out",root+"/tb/asc_tb.sv"]+[root+"/rtl/"+f for f in ("y18_math.sv","y18_axiom_eval.sv","asc_top.sv")],capture_output=True,text=True)
    if c.returncode: return "COMPILE_ERR "+c.stderr[:200]
    try: o = subprocess.run(["vvp",root+"/sim.out"],capture_output=True,text=True,timeout=60).stdout
    except subprocess.TimeoutExpired: return "TIMEOUT"
    return "ALL PASS" if "ALL PASS" in o else "FAIL"
if not shutil.which("iverilog"): print("SKIPPED: iverilog not found"); sys.exit(0)
b = run(R); assert b == "ALL PASS", "baseline must pass: "+b
killed = 0
for i,(f,o,n) in enumerate(M):
    d = f"/tmp/mut{i}"; shutil.rmtree(d, ignore_errors=True)
    for s in ("rtl","tb"): shutil.copytree(f"{R}/{s}", f"{d}/{s}")
    t = open(f"{d}/{f}").read(); assert o in t, (f,o)
    open(f"{d}/{f}","w").write(t.replace(o,n,1))
    r = run(d); k = r != "ALL PASS"; killed += k
    print(f"mutant {i:02d} {'KILLED' if k else 'SURVIVED'} {f}: {o} -> {n}")
print(f"MUTATION SCORE {killed}/{len(M)}")
sys.exit(0 if killed == len(M) else 1)
