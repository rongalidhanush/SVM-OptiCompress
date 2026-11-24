# Version 2 · SVM-OptiCompress for Theme A

**Dhanush Naidu, Keerthan Reddy · Amrita Vishwa Vidyapeetham · 22MAT220**

This is the current Optimization and Machine Learning version. Its interactive analysis is driven by the photo uploaded by the user: the codec, PCA, SVM/QP, conjugate-gradient solve, clustering, spatial transitions, block-cost maps, and rate comparisons all use that image. The numerical experiments use that image's own blocks and save results to a separate folder for each analysis run.

## Open the app

1. Download and extract the repository to a writable folder. In MATLAB, set **Current Folder** to `Version-2-Theme-A`.
2. Run `run_project`. Tested with MATLAB R2026a on Windows, Statistics and Machine Learning Toolbox and Optimization Toolbox. The project includes an SSIM fallback for installations without Image Processing Toolbox.
3. In **Image codec**, upload an image, select a method and compress. The **Six-image comparison** tab refreshes with the original and five reconstructions. Save the .soc stream and reopen it to demonstrate independent decoding.
4. Open **Theme A experiments** and click **Analyze current uploaded image**. PCA, covariance and correlation heatmaps, SVM/QP, CG, clustering, spatial transitions, per-block costs, codec comparisons, tables, and figures are all generated from the photo currently loaded in **Image codec** and saved in a new `results/theme_a/user_runs/<timestamp>_<image-name>/` folder.

## Follow one block through the compressor

Suppose a photo contains both smooth sky and feathered wings. Rounding away fine detail may save bytes in both places, but the visible error can differ. The encoder makes a local decision for each 8 × 8 block.

1. **Read and partition.** Convert the input to 8-bit grayscale or RGB and repeat the final row or column where padding is needed. Compute seven luminance features per block: mean intensity, standard deviation, variance, edge density, gradient energy, local entropy and high-frequency energy.
2. **Learn three settings.** During training, try strong, moderate and light quantization. Choose the setting that minimizes `J = D + 32R`, where D is mean squared error before final pixel rounding and R is bits per spatial pixel. Stronger quantization can win when its byte savings outweigh the increase in error.
3. **Spend the review budget.** At encoding time the SVM scores the three classes. Selective SVM ranks blocks by the gap between the two largest scores and reviews the smallest gaps. For N blocks it measures all three costs on floor(N/4) blocks. The score gap ranks ambiguity; the measured costs decide whether to change a prediction.
4. **Write and reconstruct.** Apply the DCT, divide coefficients by their quantization steps and round. Scan in zigzag order and encode zero runs and signed coefficients. The binary SOC1 stream carries the dimensions, settings and block classes needed for decoding. The decoder reconstructs pixels from the saved stream and removes padding.

The **Six-image comparison** tab displays the uploaded image and its five codec outputs. The **Theme A experiments** tab saves a new six-panel PNG for every analysis run.

### What the five methods compare

| Method | Decision rule | Question it answers |
|---|---|---|
| Fixed DCT | Use moderate everywhere. | What happens with one setting for the whole image? |
| Rules | Apply thresholds to block variation and edge density. | How well does a simple hand-written policy work? |
| SVM | Use the predicted class directly. | How much can the learned decision save? |
| Selective SVM | Re-evaluate the closest quarter of predictions. | Where is it worth spending extra checks? |
| Exhaustive | Evaluate all three costs for every block. | What is the lowest available block cost at these settings? |

The repository retains the original fixed gallery benchmark under `results/` as historical project material. It is not loaded by the app's upload workflow and its measurements should not be reported as results for a newly uploaded image. For a new image, use the app's **Theme A experiments** tab; its run folder contains fresh measurements and figures from that image.

## Image-specific analysis

Every **Analyze current uploaded image** run uses one selected photo as its only data source. The image is split deterministically by its own 8 × 8 blocks: PCA and the SVM/QP fit on training blocks and evaluate on held-out blocks. CG uses that photo's red channel (or grayscale channel); clustering, spatial transitions, quantization labels, block costs, and codec comparisons use the same photo. The run saves raw feature covariance, feature correlation, and the standardized covariance matrix used by PCA, with labeled heatmaps. This is a within-image evaluation, so adjacent blocks can be correlated; it does not measure generalization to other photos.

The analysis trains an image-specific three-class SVM for compression. Its binary SVM/QP comparison uses the highest quantization class versus the remaining class labels when both groups occur. If an image does not contain enough class variation for a binary problem, the run records that method as not applicable while still saving the PCA, CG, clustering, block-cost, and codec results.

## Mathematics behind the four experiments

**PCA.** Standardize the uploaded photo's training-block features, form their sample covariance matrix and sort eigenvectors by decreasing eigenvalue. Project held-out block features onto the first k directions and project back. The training-variance curve and held-out feature error are both specific to the uploaded photo. This reconstructs feature vectors; the codec reconstructs image pixels with the inverse DCT.

**Soft-margin SVM.** The primal objective is ½‖w‖² + CΣξᵢ, subject to yᵢ(wᵀxᵢ + b) ≥ 1 − ξᵢ and ξᵢ ≥ 0. Setting C = 1 fixes the trade-off between margin width and slack. In the dual, changing a pair of multipliers together preserves the equality constraint; clipping the step keeps both within [0,C]. The scratch solver tracks a KKT violation as its stopping criterion. MATLAB fitcsvm provides an independent linear-SVM baseline.

**CVXOPT.** Stack the weights, intercept and slacks into one decision vector. Only the weights receive a quadratic penalty, so the Hessian is positive semidefinite. CVXOPT solves the resulting constrained quadratic program using the same exported features and labels. Compare objective value, feasibility and duality gap before interpreting test accuracy.

**Conjugate Gradient.** Let D compute adjacent pixel differences and f be the input red channel. Minimizing ½‖u−f‖² + 4‖Du‖² gives the system (I + 8DᵀD)u = f. Its matrix is symmetric positive definite because vᵀMv = ‖v‖² + 8‖Dv‖² is positive for every nonzero v. This permits CG to solve the sparse system without forming a dense inverse. The reported residual is ‖Mu−f‖/‖f‖.


## Results saved for each image

Each timestamped run folder includes the original image, block features and labels, image-specific PCA/SVM/QP/CG tables, raw and standardized feature covariance matrices, the feature correlation matrix, cluster assignments and profile, spatial transition matrices, every block's three quantization costs, compression metrics, and reconstructed images. Figures include PCA variance/error, covariance and correlation heatmaps, SVM and CG convergence, QP margins, cluster map, transition heatmap, block-cost map, rate-distortion curve, and the six-panel codec comparison.

## Reproduce the results

From this version folder, run the analysis in MATLAB. The no-argument form opens a file picker:

```matlab
run_theme_a
```

It will prompt you to choose a photo. To run directly from MATLAB with a path:

```matlab
run_theme_a('C:\\path\\to\\your\\photo.jpg')
```

Or upload a photo in **Image codec** and choose **Theme A experiments → Analyze current uploaded image**. The output folder is `results/theme_a/user_runs/<timestamp>_<image-name>/`. It contains per-image CSVs and PNGs. Large photos are sampled to at most 800 pixels on the longest side only for the CG smoothing solve; compression, blocks, PCA, SVM, and clustering use the original image dimensions.

For the optional CVXOPT solver, install its dependencies first:

```sh
python -m pip install numpy cvxopt==1.3.2
```

Then add its result to a run with a valid binary split by passing that run folder:

```sh
python theme_a_cvxopt.py "results/theme_a/user_runs/<timestamp>_<image-name>"
```

The Python solver reads that run's `svm_train.csv` and `svm_test.csv` and writes its measurements into the same run folder. MATLAB `quadprog` is already included in the main run.

| Other MATLAB command | Output or purpose |
|---|---|
| `run_demo` | Regenerates the five-method compression benchmark, decoded images and plots. |
| `setup; run_selective_pilot` | Compares selective, ordinary SVM and expected random-review costs on the same images. |
| `train_svm_model(image)` | Fits a three-class SVM using the supplied image's own block features and labels. |
| `run_tests` | Runs the compression project’s regression suite, including its gallery startup check. |

## Five-minute demonstration

1. In **Image codec**, upload your photo and compress it with **Selective SVM**. Point out the original and reconstruction, then distinguish blocks reviewed from decisions changed.
2. Open **Six-image comparison** to see the uploaded photo and all five codec outputs.
3. Open **Block cost** and **Clustering** to inspect current-photo costs, clusters, and spatial transitions.
4. Open **Theme A experiments**, click **Analyze current uploaded image**, and use its result dropdown to inspect PCA, covariance/correlation heatmaps, SVM/QP, CG, rate-distortion, clustering, transitions, and block-cost outputs. Each run is saved to a new timestamped folder.
5. Explain that the split is within one photo; block results do not establish generalization to other photos. If the image has only one cost class, the binary solver comparison is marked not applicable.

### If a command does not work

- **MATLAB cannot find run_project:** check `pwd`. The Current Folder should contain both `run_project.m` and `run_theme_a.m`.
- **The app opens without the Theme A tab:** close the old window and run `which run_project -all`. Select the Version 2 folder and launch the app again.
- **Python cannot import cvxopt:** use the same Python executable for the pip install and the solver command. If input CSVs are missing, run `run_theme_a` in MATLAB first.
- **Need to preserve earlier measurements:** use a separate working copy before regenerating outputs or retraining. The batch scripts reuse the named result files.


## Read the implementation

Start with [the MATLAB experiments](run_theme_a.m) and [the CVXOPT primal](theme_a_cvxopt.py) for the course methods. For the compression algorithm, follow [the block review policy](research/selective_quantizers.m), [encoder](src/compression/compress_image.m) and [decoder](src/decompression/decompress_image.m). The [Theme A guide](documentation/theme_a.md) explains the equations, data split, convergence tests and rubric mapping. The [codec specification](documentation/algorithms.md) explains file layout and metric definitions.

[Repository overview](../README.md) · [Original compression project](../Version-1/README.md)
