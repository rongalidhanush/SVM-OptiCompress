# Theme A: uploaded-image analysis

Theme A now analyzes one user-selected photo end to end. The active app flow does not load the old MATLAB sample-photo split or a stored SVM model. Features, rate-distortion labels, training/test blocks, PCA, SVM/QP, CG, clustering, transitions, block costs, and codec figures all come from the selected image.

## Run it

In MATLAB, set Current Folder to the project root and run `run_project`. Upload a photo under **Image codec**, then click **Theme A experiments → Analyze current uploaded image**. To run from the command window, use `run_theme_a` and select a photo in the dialog, or call:

```matlab
run_theme_a('C:\\path\\to\\photo.jpg')
```

The operation creates a unique folder under `results/theme_a/user_runs/`, named with the run time and input image name. It preserves the uploaded file and writes all outputs into that folder so separate photos never overwrite one another.

## Image-local protocol

The input is converted to 8-bit grayscale/RGB and padded into 8 × 8 blocks. Seven luminance features and the three candidate quantization costs are calculated for every block. A deterministic within-image split reserves every fifth occurrence within each derived cost class for evaluation; other blocks train the models. This means training and held-out blocks all come from the same uploaded photo. Neighboring image blocks may be correlated, so these metrics describe that photo and do not prove performance on other photos.

PCA standardization and covariance are fitted on the training blocks, and the held-out feature rows are reconstructed with the first k principal components. The codec SVM learns the image's quantization labels from its training blocks. The binary scratch-SVM and QP comparison uses the highest class present as the positive class and the remaining classes as negative. It is marked not applicable if the photo does not contain both classes in the training split. CVXOPT is optional; MATLAB `quadprog` runs in the main analysis.

The run also exports a raw feature covariance matrix, a Pearson correlation matrix, and the covariance matrix of the standardized training features used by PCA. Their heatmaps use the same seven feature names on both axes. Covariance values retain the original feature units and can have very different scales; correlation values are normalized to [-1, 1]. A constant feature has undefined correlation and is displayed as `NA` in the heatmap.

The CG demonstration constructs the sparse system

\[
(I+8D^\mathsf{T}D)u=f
\]

from the uploaded photo's red (or grayscale) channel. If the image exceeds 800 pixels on its longest dimension, the CG input alone is sampled down to that limit to bound memory. `cg.csv` records both original and solver dimensions. The compression and block feature calculations use the original resolution.

## Files written for each image

| Output | Contents |
|---|---|
| `input_image.*`, `run_metadata.csv` | Input copy, dimensions, source path and settings. |
| `block_features.csv`, `class_distribution.csv` | Seven features, quantization label, block coordinates, split, and per-class counts for every image block. |
| `pca.csv`, `pca_results.png` | Image-specific training variance and held-out feature reconstruction error. |
| `feature_covariance.csv`, `feature_covariance.png` | Raw covariance between the seven training-block features. |
| `feature_correlation.csv`, `feature_correlation.png` | Pearson correlations between training-block features, on the [-1, 1] scale. |
| `pca_covariance.csv`, `pca_covariance.png` | Covariance of standardized training features; this is the matrix used for PCA. |
| `svm.csv`, `svm_train.csv`, `svm_test.csv`, `svm_convergence.png` | Scratch SVM and `fitcsvm` results, binary data when available, and KKT history. |
| `quadprog.csv`, `svm_qp_margins.png` | Image-specific primal QP status, objective, feasibility, test accuracy, and margin plot. |
| `cg.csv`, `cg_residual.csv`, `cg_convergence.png`, `cg_smoothed_channel.png` | Sparse system size, iterations, residual history and smoothing result. |
| `cluster_profile.csv`, `cluster_map.csv`, `cluster_map.png` | Cluster summaries and each block's cluster assignment. |
| `spatial_transition_counts.csv`, `spatial_transition_probabilities.csv`, `spatial_transitions.png` | Observed horizontal transitions and conditional probabilities. |
| `block_costs.csv`, `block_cost_map.csv`, `block_cost_map.png` | All three quantizer costs and the selected class for every block. |
| `compression_metrics.csv`, `compression_comparison.png`, `reconstruction_*.png` | Original plus five codecs and per-method quality/size/timing metrics at the selected level and scale. |
| `rate_curves.csv`, `matched_rates.csv`, `rate_distortion.png` | Rate/quality comparisons for the uploaded photo. |
| `image_svm_model.mat`, `binary_svm_solution.mat` | Models and solver variables for reproducibility. |

The Theme A tab dropdown displays each result table and its matching graph/map. The existing app tabs also remain image-specific: the six-image gallery updates after upload, PCA/optimization controls operate on the current image model, and clustering/transitions/block-cost controls use the currently loaded image.

## Optional CVXOPT run

Install NumPy and CVXOPT, then run the solver on the custom run folder:

```sh
python -m pip install numpy cvxopt==1.3.2
python theme_a_cvxopt.py "results/theme_a/user_runs/<timestamp>_<image-name>"
```

The Python solver writes `cvxopt.csv` in that same folder. It requires a valid two-class SVM split; otherwise use the saved `quadprog.csv` status explaining why the binary formulation was not applicable.

## Interpretation

The “training variance” curve is fitted from the uploaded photo's training blocks, not from a library sample image. SVM objective values describe the uploaded photo's training split. Held-out accuracy describes its reserved blocks and should be reported with `class_distribution.csv`. The clustering and rate-distortion outputs describe the same input image. Keep the separate synthetic codec pilot in `results/metrics/` identified as its own experiment; it is not substituted for an uploaded-image result.
