# Version 2 · Final · SVM-OptiCompress

**Dhanush Naidu · Keerthan Reddy · Amrita Vishwa Vidyapeetham · 22MAT220**

This is the final uploaded-image version of the MATLAB compression laboratory. It partitions an image into 8 × 8 blocks, extracts local statistics, predicts quantization classes with an SVM, writes a SOC1 stream, and reconstructs the image. The final Theme A workflow also adds simulated quantum-edge analysis, SVM/QP checks, conjugate-gradient smoothing, clustering, spatial transitions, covariance/correlation heatmaps, rate comparisons and Richardson–Lucy photo restoration.

## Run the application

1. Set MATLAB’s Current Folder to `Version-2-Final`.
2. Run `run_project`.
3. In **Image codec**, upload a JPG/PNG, choose a method and a level from **0.1 to 150**, then click **Compress**.
4. Save the `.soc` stream. Use **Open compressed file → Decompress** to decode it and save the reconstructed PNG.
5. For blurry photos, open **Photo restoration**, set blur width and iterations, click **Reconstruct photo**, then save the Richardson–Lucy result as PNG.
6. Open **Theme A experiments → Analyze current uploaded image**. The run is saved under `results/theme_a/user_runs/<timestamp>_<image-name>/`.

## What the final workflow computes

- **Codec:** DCT, quantization, zig-zag/run-length coding and SOC1 decoding.
- **Selective SVM:** reviews the quarter of blocks with the smallest score gap between predicted classes.
- **SVM/QP:** compares the scratch margin solver, MATLAB `fitcsvm`, `quadprog` and optional CVXOPT results.
- **Quantum edge simulation:** represents each normalized 8 × 8 luminance tile as 64 amplitudes (`2⁶ = 64`) and uses a Hadamard-style neighbour difference `(a − b)/√2` to produce an edge-probability map. This is a classical simulation for analysis, not a claim of hardware execution.
- **Numerical experiments:** conjugate-gradient residuals, K-means clusters, spatial transition probabilities, block-cost maps, covariance/correlation heatmaps and bitrate–distortion comparisons.
- **Photo restoration:** Richardson–Lucy iterative deconvolution for ordinary blurry images; blur width and iteration count are user controls.

Every analysis uses the currently uploaded photo. Outputs include CSV tables, PNG figures, reconstructed images and a copy of the input image in the timestamped run folder.

## Five-minute demonstration

1. Upload a photo and compress it with **Selective SVM**; point out the original, reconstruction, reviewed blocks and changed decisions.
2. Open **Six-image comparison** to show the five codec outputs.
3. Open **Clustering**, **Spatial transitions** and **Block cost** to explain current-image structure.
4. Run **Analyze current uploaded image** and show the quantum edge map, SVM/QP, CG, covariance/correlation, rate, clustering and transition outputs.
5. Open **Photo restoration** and compare the blurry input with its Richardson–Lucy reconstruction.

## Requirements

- MATLAB R2026a or newer.
- Statistics and Machine Learning Toolbox.
- Optimization Toolbox.
- Optional CVXOPT comparison: Python with `numpy` and `cvxopt==1.3.2`.

## Credits

Developed by **Dhanush Naidu** and **Keerthan Reddy**, Amrita Vishwa Vidyapeetham, for 22MAT220 Mathematics for Computing III.
