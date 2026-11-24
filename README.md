# SVM-OptiCompress

**Dhanush Naidu · Amrita Vishwa Vidyapeetham**  
Mathematics for Computing 3 · 22MAT220

| Version | Project |
|---|---|
| [Version 1 — Original](Version-1-Original/) | Original MATLAB compression app with five encoders, selective SVM review, six-image gallery and benchmark results. |
| [Version 2 — Theme A](Version-2-Theme-A/) | Current coursework version. Includes the compression app plus real-image PCA, a from-scratch SVM and library comparison, a CVXOPT quadratic program and sparse Conjugate Gradient experiments. |

## Run the current version

Open MATLAB in the repository root and run:

```matlab
cd('Version-2-Theme-A')
run_project
```

Use **Six-image comparison** for the codec demo and **Theme A experiments** for the four course methods. To reproduce the optimization results from source, see the [Theme A setup and experiment guide](Version-2-Theme-A/documentation/theme_a.md).

To run the original version, start MATLAB in the repository root, open the Version-1-Original folder and run the same launcher.
