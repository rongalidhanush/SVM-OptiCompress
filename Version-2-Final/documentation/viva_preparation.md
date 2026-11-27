# Five-minute demonstration
1. Run run_project. Leave Selective SVM and level 1 selected, then click Compress. Read the reviewed and changed counts aloud. The first counts every block whose compression options were measured. The second counts those where that measurement changed the SVM's decision.
2. Show the class map, counts, reconstruction, actual bytes and bitrate. Save the stream. Open it and decompress again to demonstrate independent reconstruction.
3. Show the held-out confusion matrix. Rows are rate-distortion labels, columns are predictions. Explain which classes the model confuses.
4. Solve the binary QP. Point out the support vectors, decision boundary, unit-margin contours and numerical KKT residuals.
5. Run the comparison and discuss two nearby bitrate points. Use the CSV for exact values. End with the optional quantum edge analysis view if requested.

## Questions to rehearse
**What is your research question?** If I have time to double-check only a quarter of the image blocks, can the gap between SVM scores help me find costly mistakes? For example, with 100 blocks I rank the predictions by their top-two score gap and recheck the closest 25. For each, I try strong, moderate and light compression at the selected level and scale, then choose the lowest error-plus-rate cost. All final choices are stored in the file.

**Where is that in the code?** Open research/selective_quantizers.m. Point to predict, the sorted score gap, the review budget, and the call to label_blocks. Then open src/compression/compress_image.m to show how the final choices control quantization and file writing.

**How do you judge success?** Use run_selective_pilot to compare review policies at equal budgets. Use Rate comparisons to examine file bytes, PSNR and encoder time against ordinary SVM and exhaustive review. Similar size makes quality easier to compare. SVM inference itself takes time, so checking fewer blocks does not guarantee faster encoding.

For a repeatable live example, use the bundled scene_12.png and leave the block row and column at 1. At a penalty of 0 the light setting wins. At 32 the strong setting wins. Point to the Bytes and MSE columns to explain the switch.

**How can I show where the training labels come from?** Open Block cost and set the penalty to zero. The smallest mean squared error wins. Increase the penalty and compare the costs again. A candidate that saves enough bytes can now win even if its error is larger. Some blocks keep the same winner. The byte counts include the block class and coefficient records. Each spatial block has 64 pixels, so its bits per pixel equal bytes × 8 / 64. The interactive calculation uses the nominal quantizer level and scale of 1. It explores how a training label is chosen for that block.

**What does the transition matrix predict?** Run Clustering and open Spatial transitions. Read across the row for the current cluster. Each entry equals the number of times that right neighbor was seen divided by the total observed right neighbors for that row's cluster. A largest entry gives a most frequent next cluster when moving right. Row boundaries are excluded. A NaN row has no observations. The probabilities are estimated on the displayed image and describe spatial adjacency. Forecasting changes over time would require a sequence of images.

**What does clustering discover?** On the Clustering tab, run k-means with three groups. Choose a colored region and use its table row to describe the blocks there. Higher average gradient energy indicates stronger changes between neighboring pixels. Each iteration assigns blocks to their nearest centroid and updates each centroid to the mean of its assigned blocks. The displayed sum of squares measures spread around the centroids in standardized feature space. Group IDs are ordered by average gradient energy within this image. The SVM learns its compression decisions from rate-distortion labels.

**Where do the labels come from?** Encode each training block three ways, measure squared error and bytes and select the lowest rate-distortion cost. A higher rate penalty favors smaller files.

**Why split by image?** Adjacent blocks from one scene share visual structure. Holding out whole scenes reduces leakage between training and evaluation.

**Why use slack variables?** Compression classes can overlap in feature space. Slack makes the margin constraints feasible while C controls the cost of violations.

**What makes the optimization convex?** The quadratic weight penalty has a positive semidefinite Hessian, the slack penalty is linear and all constraints are affine.

**How does the decoder know each quantizer?** The stream stores the class per block plus the global level and scale. The SOC1 specification fixes the quantizer formula and zigzag order.

**Can SVM make a larger file?** Yes. Weak quantization retains more nonzeros and records consume bytes. Compare all methods at similar measured rates.

**How would you establish generalization?** Train and test on larger independent image collections, keep scene variants in one split and report per-class and per-image results. The supplied data illustrate the workflow.

The simulated quantum circuit amplitude-encodes each 8 × 8 brightness block in six qubits. A Hadamard gate on a row or column address bit makes the difference of neighboring amplitudes observable. The map averages the two measurement probabilities. A black block is assigned zero contrast.

**What do the covariance and correlation heatmaps show?** Each cell compares one block feature with another. Covariance retains the features' original units, so its diagonal contains feature variances and its color scale may be dominated by large-scale features. Correlation normalizes pairwise covariance to values from -1 to 1, so its strength and direction are easier to compare across features. A constant feature has undefined correlation and is marked NA.

**What data are in each matrix?** They are calculated from training blocks of the currently uploaded image. The matching CSV and heatmap are saved in that image's timestamped Theme A run folder.
