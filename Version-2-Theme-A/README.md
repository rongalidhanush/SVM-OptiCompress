# Version 2 · SVM-OptiCompress for Theme A

**Dhanush Naidu · Amrita Vishwa Vidyapeetham · 22MAT220**

This is the current Optimization and Machine Learning version. It combines a working adaptive image codec with four reproducible numerical experiments. The codec asks which compression decisions deserve review. The numerical experiments ask how well a low-dimensional feature representation reconstructs held-out data and how closely independent solvers agree on the same mathematical problem.

## Open the app

1. Download and extract the repository to a writable folder. In MATLAB, set **Current Folder** to `Version-2-Theme-A`.
2. Run `run_project`. Tested with MATLAB R2026a on Windows, Statistics and Machine Learning Toolbox and Optimization Toolbox. The project includes an SSIM fallback for installations without Image Processing Toolbox.
3. In **Six-image comparison**, inspect the original and five reconstructions. In **Image codec**, upload an image, select a method and compress. Save the .soc stream and reopen it to demonstrate independent decoding.
4. Open **Theme A experiments**. The dropdown displays PCA, scratch SVM versus fitcsvm, saved CVXOPT results and Conjugate Gradient. **Re-run MATLAB experiments** recomputes the MATLAB outputs. Run Python separately to refresh CVXOPT.

## Four experiments and their evidence

| Method | Setup and measured result |
|---|---|
| [Real-image PCA](results/theme_a/pca.csv) | Fit scaling and covariance on street and nebula images. Three PCs retain 91.99% of training variance. On the held-out peppers image the relative feature reconstruction error is 0.3265 with three PCs and 0.0910 with five. |
| [SVM from scratch](results/theme_a/svm.csv) | A dual pair-update solver preserves the label-balance constraint and clips updates to the box constraints. On identical scaled training rows, its primal objective is 66.93635 versus 66.94048 for linear fitcsvm. |
| [Constrained convex optimization](results/theme_a/cvxopt.csv) | CVXOPT solves the same soft-margin primal with affine margin and slack constraints. It reports optimal in 13 iterations, with objective 66.93627 and duality gap 9.76 × 10⁻⁶. |
| [Krylov method](results/theme_a/cg.csv) | A sparse positive-definite pixel-smoothing system has 196,608 unknowns. Custom CG and MATLAB pcg both take 72 iterations. The recomputed relative residual is 7.86 × 10⁻⁹. |

The binary held-out split contains 3,050 strong-compression blocks and one light block. Always predicting strong also achieves 99.97% accuracy. The comparison therefore supports **agreement between solvers**; minority-class performance needs more evidence. The desktop codec’s 70% classifier result comes from a separate three-class synthetic benchmark.

![SVM optimality violation and CG relative residual versus iteration](results/theme_a/convergence.png)

## Reproduce the results

From this version folder, run in MATLAB:

```matlab
run_theme_a
```

The script locates three MathWorks sample images in the MATLAB installation, computes seven features per block, exports the training and test matrices, and writes the PCA, SVM and CG results under `results/theme_a/`. The saved [block dataset](results/theme_a/real_blocks.csv) records the source image, block index and compression label.

Then, from a terminal in the **same folder**, run:

```sh
python -m pip install numpy cvxopt==1.3.2
python theme_a_cvxopt.py
```

The Python solver uses the exported MATLAB matrices and writes its measurements to `results/theme_a/cvxopt.csv`. Python is required only for reproducing that solve.

| Other MATLAB command | Output or purpose |
|---|---|
| `run_demo` | Regenerates the five-method compression benchmark, decoded images and plots. |
| `setup; run_selective_pilot` | Compares selective, ordinary SVM and expected random-review costs on the same images. |
| `train_svm_model` | Retrains and replaces the stored three-class codec model. |
| `run_tests` | Runs the compression project’s regression suite, including its gallery startup check. |

## Read the implementation

Start with [the MATLAB experiments](run_theme_a.m) and [the CVXOPT primal](theme_a_cvxopt.py) for the course methods. For the compression algorithm, follow [the block review policy](research/selective_quantizers.m), [encoder](src/compression/compress_image.m) and [decoder](src/decompression/decompress_image.m). The [Theme A guide](documentation/theme_a.md) explains the equations, data split, convergence tests and rubric mapping. The [codec specification](documentation/algorithms.md) explains file layout and metric definitions.

[Repository overview](../README.md) · [Original compression project](../Version-1-Original/README.md)
