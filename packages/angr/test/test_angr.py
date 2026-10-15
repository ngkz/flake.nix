"""Symbolic execution check for the packaged angr suite.

Recover the crackme password from stdin. Every solution angr reports is read back
from a solver model, so this fails when the vendored Rust solver bridge
(native/clarirs-z3) is built against an incompatible libz3.
"""

import logging

import angr

logging.getLogger("angr").setLevel("CRITICAL")

proj = angr.Project("./crackme")
print("loaded", proj.filename, proj.arch.name, proj.simos.name)

state = proj.factory.entry_state(stdin=angr.SimFile)
sm = proj.factory.simgr(state)
sm.explore(find=lambda s: b"Congrats" in s.posix.dumps(1))

if not sm.found:
    stashes = {name: len(states) for name, states in sm._stashes.items() if states}
    raise SystemExit(f"symbolic execution reached no success state, stashes: {stashes}")

password = sm.found[0].posix.dumps(0)
print("recovered password:", password)
assert password.startswith(b"angr-nix!"), password
