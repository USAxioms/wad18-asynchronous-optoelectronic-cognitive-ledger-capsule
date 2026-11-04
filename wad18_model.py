# Integer-only golden model (no floats). Cross-checks WAD semantics used by the RTL.
WAD = 10**18; M = 1 << 127
def fits(x): return -M <= x < M
def mul(a, b):
    p = a * b; q = abs(p) // WAD
    return (-q if p < 0 else q)   # trunc toward zero == SV '/'
assert mul(3*WAD, 4*WAD) == 12*WAD and mul(-WAD, 5*WAD // 2) == -5*WAD // 2
assert mul(1, 1) == 0 and mul(-1, 1) == 0
assert not fits(mul(2*WAD, 1 << 126)) and fits(mul(WAD, 1 << 126))
assert not fits((1 << 126) + (1 << 126))
print("MODEL OK")
