"""Run after run_theme_a. Solve the identical linear soft-margin primal with CVXOPT."""
from pathlib import Path
import csv
import sys
import numpy as np
from cvxopt import matrix, solvers

out = (Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else
       Path(__file__).resolve().parent / "results" / "theme_a")
train, test = [np.loadtxt(out / f"svm_{split}.csv", delimiter=",") for split in ("train", "test")]
X, y = train[:, :-1], train[:, -1]
n, d = X.shape
P = np.diag(np.r_[np.ones(d), np.zeros(n + 1)])
q = np.r_[np.zeros(d + 1), np.ones(n)]
G = np.vstack((np.c_[-y[:, None]*X, -y, -np.eye(n)], np.c_[np.zeros((n,d+1)), -np.eye(n)]))
h = np.r_[-np.ones(n), np.zeros(n)]
sol = solvers.qp(matrix(P), matrix(q), matrix(G), matrix(h))
assert sol["status"] == "optimal", sol["status"]
z = np.asarray(sol["x"]).ravel()
acc = np.mean((test[:, :-1] @ z[:d] + z[d] >= 0) == (test[:, -1] > 0))
violation = max(0., np.max(G @ z-h))
assert violation < 1e-5
with (out/"cvxopt.csv").open("w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Status","Objective","HeldOutAccuracy","MaxViolation","DualityGap","Iterations"])
    writer.writerow([sol["status"],sol["primal objective"],acc,violation,sol["gap"],sol["iterations"]])
