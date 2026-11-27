# Version 2 · Final · SVM-OptiCompress

**Dhanush Naidu · Keerthan Reddy · Amrita Vishwa Vidyapeetham · 22MAT220**  
Mathematics for Computing III · End-semester project

## 1. Project overview

SVM-OptiCompress is an interactive MATLAB laboratory for adaptive image compression and numerical analysis. The encoder divides an image into 8 × 8 blocks, measures the visual content of each block, predicts a quantization class with a support vector machine (SVM), and writes a compact SOC1 stream. The decoder reads that stream and reconstructs the image.

The final Version 2 workflow is image-specific: when a user uploads a new photo, the block features, SVM/QP measurements, simulated quantum-edge map, clusters, spatial transitions, block costs, rate comparisons and reconstructed images are generated from that photo. Each analysis is saved in a new timestamped folder so that results from different images do not overwrite one another.

The project also contains a Richardson–Lucy photo-restoration panel for ordinary blurry JPG/PNG images. Restoration and compression are complementary workflows: compression reduces storage, while Richardson–Lucy attempts to recover visual sharpness from a blur model.

## 2. What is new in the final version

- The feature-analysis experiment uses **Simulated Quantum Edge Analysis**. A normalized 8 × 8 brightness tile is treated as 64 amplitudes, and a Hadamard-style neighbour difference produces an interpretable edge-probability map.
- The app tab is labelled **Optimization & Quantum** and the Theme A dropdown contains **Quantum edge probabilities**.
- The compression level control accepts values from **0.1 through 150**. Higher values generally apply stronger quantization and can remove more detail.
- The app includes **Photo restoration** with blur-width and iteration controls and a side-by-side input/reconstruction view.
- Decompression displays the decoded image and provides a **Save decoded PNG** action.
- All uploaded-image outputs are written to `results/theme_a/user_runs/<timestamp>_<image-name>/`.

## 3. Requirements

- MATLAB R2026a or newer.
- Statistics and Machine Learning Toolbox for `fitcsvm` and clustering.
- Optimization Toolbox for `quadprog`.
- Python with `numpy` and `cvxopt==1.3.2` only for the optional CVXOPT comparison.

The project contains an SSIM fallback for installations without Image Processing Toolbox. Run MATLAB from a writable copy of this folder.

## 4. Running the application

1. Clone or download the repository.
2. Open MATLAB and set **Current Folder** to `Version-2-Final`.
3. Run:

```matlab
run_project
```

The app opens on **Six-image comparison**.

### 4.1 Image codec demonstration

1. Open **Image codec → Upload image** and choose a JPG, PNG, BMP or TIFF image.
2. Select a method: Fixed DCT, Rules, SVM, Selective SVM or Exhaustive.
3. Select a compression **Level** from 0.1 to 150 and a scale.
4. Click **Compress**. The app displays the original and reconstruction, file size, bits per pixel, raw ratio, MSE, PSNR, SSIM and the number of reviewed/changed blocks.
5. Click **Save compressed file** to write a `.soc` stream.
6. Click **Open compressed file**, select the saved stream, and click **Decompress**. The decoded image appears in the app and can be saved as a PNG.

### 4.2 Theme A analysis of the uploaded image

1. Upload the image in **Image codec** first.
2. Open **Theme A experiments**.
3. Click **Analyze current uploaded image**.
4. Use the result dropdown to inspect the quantum edge map, covariance/correlation matrices, SVM/QP results, CG convergence, clustering, spatial transitions, block costs, rate curves and codec reconstructions.

The analysis creates a folder such as:

```text
results/theme_a/user_runs/20261125_070637_my_photo/
```

The folder stores the input image, CSV tables, PNG figures, reconstructed images and run metadata. The same image and settings reproduce the same deterministic block-level measurements, subject to MATLAB numerical tolerances.

### 4.3 Richardson–Lucy photo restoration

1. Open the **Photo restoration** tab.
2. Click **Open ordinary photo** and select a blurry image.
3. Set **Blur width (pixels)**. A practical starting range is about 0.4–8 pixels.
4. Set **Iterations**. Start with 16; reduce the value if bright halos or noise appear.
5. Click **Reconstruct photo** to compare the input on the left with the estimated reconstruction on the right.
6. Click **Save reconstruction as PNG**.

This operation does not use a `.soc` file. It is an iterative deconvolution experiment and cannot recreate detail that was never captured by the camera.

## 5. Following one 8 × 8 block through the codec

Suppose a photo contains both a smooth sky and a feathered wing. Applying the same quantization everywhere wastes bits in the sky or damages the wing. The encoder therefore makes a local decision for every block.

1. **Partition.** The image is converted to the supported numeric representation, padded when necessary, and split into 8 × 8 blocks.
2. **Extract features.** Seven luminance features are measured: mean intensity, standard deviation, variance, edge density, gradient energy, local entropy and high-frequency DCT energy.
3. **Create labels.** Strong, moderate and light quantization are tested with the rate–distortion cost

   `J = D + λR`,

   where `D` is block mean-squared error, `R` is the estimated rate in bits per spatial pixel, and the default `λ` is 32.
4. **Predict.** The SVM predicts one of the three quantization classes from the block features.
5. **Review ambiguity.** Selective SVM computes the gap between the two largest class scores and reviews the smallest-gap quarter of blocks. It evaluates all three candidate costs only for that budget and changes a decision only when the measured cost improves.
6. **Transform and encode.** The chosen quantization table is applied after the discrete cosine transform. Coefficients are rounded, scanned in zig-zag order, and written using zero runs and signed values.
7. **Decode.** The SOC1 header stores dimensions, scale, level and block decisions. The decoder reverses the scan, dequantizes, applies the inverse DCT and removes padding.

## 6. The five codec methods

| Method | Decision rule | Purpose |
|---|---|---|
| Fixed DCT | Use the moderate setting for every block. | Baseline showing one global setting. |
| Rules | Use thresholds on variation and edge density. | Simple hand-designed policy. |
| SVM | Use the predicted class directly. | Measures the learned classifier’s decision. |
| Selective SVM | Re-evaluate the most ambiguous quarter of blocks. | Spends extra computation where the classifier is uncertain. |
| Exhaustive | Evaluate all three costs for every block. | Reference minimum among the available candidate settings. |

The app reports reviewed blocks separately from changed decisions. A reviewed block is inspected by the selective policy; a changed decision is one whose original SVM class is replaced after cost comparison.

## 7. Theme A experiments and mathematics

### 7.1 Simulated Quantum Edge Analysis

For an 8 × 8 luminance tile, flatten the 64 nonnegative intensities and normalize them as amplitudes:

`aᵢ = xᵢ / ‖x‖₂`,  i = 1, …, 64.

Six address qubits are sufficient because `2⁶ = 64`. A Hadamard-style difference on neighbouring amplitudes uses

`h(a,b) = (a − b) / √2`.

The implementation computes horizontal and vertical neighbour differences, squares them to obtain probabilities, and averages them for the block’s edge score. The output is a spatial probability map: brighter blocks have stronger local contrast. A black tile is assigned zero contrast by convention. This is a classical simulation of quantum-inspired amplitude operations; no quantum hardware is required.

The run saves `quantum_edges.csv` and `quantum_edges.png`.

### 7.2 Soft-margin SVM

The binary solver demonstration uses the primal objective

`min ½‖w‖² + C Σ ξᵢ`

subject to

`yᵢ(wᵀxᵢ + b) ≥ 1 − ξᵢ`,  `ξᵢ ≥ 0`.

The weight norm controls the margin width, while slack variables allow violations at a penalty. The project compares the scratch solver with MATLAB `fitcsvm` and records the KKT history, objective and held-out accuracy when a valid binary split exists.

### 7.3 Constrained quadratic program

The QP form places the SVM weights, intercept and slacks in one decision vector. The Hessian penalizes the weights, while affine inequalities enforce the margin and nonnegative slacks. MATLAB `quadprog` is the built-in convex solver. The optional Python script `theme_a_cvxopt.py` solves the equivalent primal with CVXOPT. Compare objective, feasibility and duality gap before interpreting accuracy.

### 7.4 Conjugate Gradient

For the smoothing experiment, let `D` compute adjacent-pixel differences and `f` be the uploaded red or grayscale channel. Minimizing

`½‖u − f‖² + 4‖Du‖²`

gives

`(I + 8DᵀD)u = f`.

The matrix is symmetric positive definite because `vᵀMv = ‖v‖² + 8‖Dv‖² > 0` for nonzero `v`. Therefore CG solves the sparse system without forming a dense inverse. The run records iteration count and relative residual `‖Mu − f‖ / ‖f‖`.

### 7.5 Covariance, correlation, clustering and transitions

The raw feature covariance matrix keeps the original feature scales. The correlation matrix normalizes each pair to the range −1 to +1, with diagonal entries equal to 1. K-means groups blocks with similar features without using compression labels. The spatial-transition matrix counts which cluster most often occurs immediately to the right of the current cluster.

## 8. Files generated for every uploaded image

| Output | Meaning |
|---|---|
| `run_metadata.csv` | Source name, dimensions, channels, level, scale, rate penalty and requested cluster count. |
| `block_features.csv` | Seven features, block coordinates, quantization class and train/held-out split. |
| `quantum_edges.csv/png` | Per-block horizontal/vertical/mean simulated edge probabilities and heatmap. |
| `feature_covariance.csv/png` | Raw covariance values and heatmap. |
| `feature_correlation.csv/png` | Normalized feature correlations and heatmap. |
| `svm.csv`, `svm_train.csv`, `svm_test.csv` | SVM objectives, data matrices and held-out measurements. |
| `quadprog.csv` and `binary_svm_solution.mat` | QP status, objective, feasibility information and solver state. |
| `cg.csv`, `cg_residual.csv`, `cg_convergence.png` | CG dimensions, iterations and residual history. |
| `cluster_map.csv`, `cluster_profile.csv`, `clustering_summary.csv` | Cluster assignments and within-cluster summaries. |
| `spatial_transition_probabilities.csv` | Neighbour-transition probabilities. |
| `block_costs.csv`, `block_cost_map.png` | Candidate cost for every block and spatial cost map. |
| `compression_metrics.csv`, `compression_comparison.png` | File size, bitrate, MSE, PSNR and SSIM for codec methods. |
| `rate_curves.csv`, `rate_distortion.png` | Measured bitrate–quality operating points. |
| `reconstruction_*.png` | Decoded output from each codec method. |

## 9. Important folders and files

| Path | Responsibility |
|---|---|
| `run_project.m` | Main launcher for the desktop app. |
| `run_theme_a.m` | Runs the complete uploaded-image analysis and creates a timestamped result folder. |
| `run_demo.m` | Regenerates the bundled multi-image codec demonstration. |
| `run_tests.m` | Runs the MATLAB regression/startup tests. |
| `app/OptiCompressApp.m` | Builds the tabs, controls, callbacks and image displays. |
| `app/theme_a_panel.m` | Builds the Theme A experiment controls and result dropdown. |
| `app/restoration_panel.m` | Builds the Photo restoration interface. |
| `src/compression/compress_image.m` | DCT quantization, block review and SOC1 encoding. |
| `src/decompression/decompress_image.m` | SOC1 parsing, inverse DCT and image reconstruction. |
| `src/optimization/quantum_edges.m` | Simulated six-qubit/64-state edge-probability analysis. |
| `src/optimization/svm_qp_demo.m` | Scratch SVM and QP demonstration. |
| `src/optimization/solve_image_qp.m` | Image-specific binary QP solve. |
| `src/optimization/restore_photo.m` | Richardson–Lucy iterative deconvolution. |
| `src/features/block_features.m` | Computes the seven block features. |
| `src/features/cluster_blocks.m` | K-means block clustering. |
| `src/features/spatial_transitions.m` | Builds cluster-neighbour transition matrices. |
| `src/metrics/compare_methods.m` | Computes codec rate and quality comparisons. |
| `theme_a_cvxopt.py` | Optional CVXOPT comparison using exported CSV files. |
| `results/theme_a/user_runs/` | Image-specific CSV, PNG and reconstructed-image outputs. |

## 10. Reproduce results from MATLAB or Python

Analyze a chosen photo through the file picker:

```matlab
run_theme_a
```

Analyze a known path directly:

```matlab
run_theme_a('C:\\path\\to\\your\\photo.jpg')
```

Run the optional CVXOPT comparison after installing its dependencies:

```sh
python -m pip install numpy cvxopt==1.3.2
python theme_a_cvxopt.py "results/theme_a/user_runs/<timestamp>_<image-name>"
```

Other useful commands:

| Command | Purpose |
|---|---|
| `run_demo` | Rebuilds the bundled five-method compression benchmark. |
| `setup` | Adds project subfolders to the MATLAB path and returns the project root. |
| `train_svm_model(image)` | Trains/replaces the three-class codec model for an image. |
| `run_tests` | Checks codec functions, app startup and representative outputs. |

## 11. Limitations and interpretation

- The quantum module is a deterministic classical simulation, not execution on a quantum processor.
- Richardson–Lucy improves blur only when the assumed blur width is reasonably close to the image formation process; it cannot restore information that was never recorded.
- Lossy compression intentionally discards information. Decompression reconstructs the encoded approximation, not the exact original, unless the lossless PNG mode is used.
- Results are image-specific. A new upload creates new measurements; bundled benchmark files should not be reported as results for a different photo.
- SVM/QP binary accuracy can be dominated by class imbalance. Report objectives, class counts, residuals and reconstruction metrics together rather than quoting accuracy alone.
- Timing depends on MATLAB version, hardware, image size and toolbox availability.

## 12. Credits

Developed by **Dhanush Naidu** and **Keerthan Reddy**, Amrita Vishwa Vidyapeetham, for 22MAT220 Mathematics for Computing III.

Repository overview: [../README.md](../README.md) · Historical baseline: [../Version-1/README.md](../Version-1/README.md)
