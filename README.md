# SVM-OptiCompress

**Dhanush Naidu · Keerthan Reddy · Amrita Vishwa Vidyapeetham**  
22MAT220 · Mathematics for Computing III · End-semester project

SVM-OptiCompress is a MATLAB image-compression laboratory. It divides an image into 8 × 8 blocks, extracts local statistics, predicts a quantization class with a selective SVM, encodes the result as a SOC1 stream, and reconstructs the image. The final version also provides image-specific Theme A experiments and a simulated quantum-edge analysis.

## Repository versions

| Folder | Purpose |
|---|---|
| [Version 1](Version-1/README.md) | Original compression baseline, five codec methods, six-image comparison and standalone SOC decoder. |
| [Version 2 · Final](Version-2-Final/README.md) | Final uploaded-image workflow with SVM/QP, conjugate gradient, clustering, spatial transitions, covariance/correlation analysis, simulated quantum edges, photo restoration and level range 0.1–150. |

The Version 1 folder is preserved as the historical baseline. Version 2 · Final is the submission version.

## Run Version 2 · Final

1. Clone or download this repository and extract it to a writable folder.
2. Open MATLAB R2026a and set the Current Folder to `Version-2-Final`.
3. Run:

```matlab
run_project
```

Upload a photo in **Image codec**, choose a codec and compression level, then click **Compress**. The app displays the input and reconstruction. Save the SOC1 file, reopen it with **Open compressed file**, and click **Decompress** to decode it.

Open **Theme A experiments** and choose **Analyze current uploaded image**. All measurements and figures are generated from the uploaded photo and saved under `results/theme_a/user_runs/<timestamp>_<image-name>/`.

## Final-version features

- Selective SVM review of the most ambiguous block decisions.
- SOC1 compression/decompression with selectable level from 0.1 to 150.
- SVM and quadratic-program optimization checks.
- Conjugate-gradient smoothing solve with residual and iteration diagnostics.
- K-means clustering, block-cost maps and spatial transition probabilities.
- Covariance and feature-correlation heatmaps.
- Simulated quantum edge analysis: a normalized 8 × 8 block is treated as 64 amplitudes, and a Hadamard-style neighbour difference produces an edge-probability map.
- Richardson–Lucy photo restoration for blurry JPG/PNG inputs, with blur-width and iteration controls.
- Per-run CSV, PNG and reconstructed-image outputs.

## Requirements

- MATLAB R2026a or newer.
- Statistics and Machine Learning Toolbox.
- Optimization Toolbox.
- Python and `cvxopt==1.3.2` only for the optional CVXOPT comparison.

## Credits

Developed by **Dhanush Naidu** and **Keerthan Reddy**, Amrita Vishwa Vidyapeetham, for 22MAT220 Mathematics for Computing III.
