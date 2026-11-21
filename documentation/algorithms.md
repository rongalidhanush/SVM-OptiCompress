# Image codec and evaluation
## From pixels to block classes
Input is converted to 8-bit grayscale or RGB. Indexed images are expanded with their palette. Floating inputs must be in [0,1]. The last row and column are replicated to multiples of eight. All planes share one class per spatial block.

The seven predictors are mean luminance, sample standard deviation, sample variance, fraction of horizontal and vertical neighbor differences exceeding 18 intensity units in magnitude, mean squared neighbor difference, 16-bin Shannon entropy in bits, and high-frequency DCT energy per pixel (frequency indices u+v ≥ 5). RGB uses weighted luminance for prediction and separate RGB planes for coding. The quantizer and reconstruction operate in intensity units.

For each training block the encoder evaluates factors 2.4 (strong), 1 (moderate) and 0.42 (light) at level and scale 1. Its candidate table contains transform-domain MSE, corresponding PSNR, encoded block bytes and cost. The orthonormal DCT preserves the squared Frobenius norm. Training distortion therefore measures squared pixel error before clipping and integer rounding. Bytes per spatial block equal one class byte, one count byte per plane and three bytes per nonzero. The shared header is constant across candidates. The label minimizes MSE + 32 × bits per spatial pixel. Exact ties favor the first, stronger class. RGB distortion averages over planes and RGB rate counts every plane. The three label costs can be inspected with the second output of label_blocks.

Fixed coding uses the moderate factor everywhere. The rule method assigns strong to standard deviation below 12, moderate otherwise, then light wherever edge density exceeds 0.26. The SVM uses one-versus-one Gaussian binary learners trained on the seven features. The operating level changes the quantizer globally while class predictions stay fixed. The training policy was calibrated at the nominal level.

## Quantizer and stream
### Selective review before encoding
The Selective SVM encoder ranks the blocks by the difference between their two highest ECOC scores. The score gap measures ambiguity and is not a calibrated probability. It reviews floor(N/4) blocks, with ties resolved in block order. At the actual level and scale it evaluates the three candidates using the same error-plus-rate objective as training, with rate penalty 32. Only reviewed blocks can change class. Exhaustive evaluates all three candidates for every block without SVM inference. Both methods emit standard SOC1 streams. The pilot uses nominal settings, and its excess cost is the mean difference from the exhaustive block cost. Final decoded quality and full encoder time are measured separately in the file comparison.

Subtract 128 and transform each plane with an orthonormal 2-D DCT. For zero-based frequencies u,v, the base step is 4 + 1.6(u+v) + 0.32(u+v)². Multiply by class factor, global level and quantization scale, round and clip the minimum step to 1. Divide by this step and round to signed integers. The decoder multiplies by the same step, applies the inverse transform, restores the shift, rounds to uint8 and crops the padded border.

| Stream field in order | Encoding |
|---|---|
| Signature and format version | Four ASCII bytes SOC1 |
| Height, width | Two little-endian uint32 values |
| Channels | uint8, either 1 or 3 |
| Level and scale | Two little-endian IEEE double values |
| Block classes | One byte per block, values 1 through 3, down each block column |
| Coefficients | Plane first, then block column, then block row. Each block has one nonzero-count byte followed by triples containing the preceding zero run (uint8) and signed coefficient (little-endian int16) |

Within each block the DCT coordinates follow alternating zigzag diagonals. Implicit zeros fill the tail. The decoder checks the signature, dimensions, class IDs, run lengths, record counts and stream length. The format has no checksum. It is a teaching codec with no chroma subsampling or entropy coder.

## Interpreting comparisons
Each method runs on the same image at nine global levels. Bytes include the entire .soc file. BPP = 8 × file bytes / original spatial pixels. Compression ratio = raw 8-bit raster bytes / .soc bytes. The size of the uploaded PNG or JPEG appears separately in the UI. A ratio below one means the stream exceeds raw raster size.

Final MSE and PSNR compare decoded 8-bit samples to the original. PSNR = 10 log10(255² / MSE). SSIM is measured per channel then averaged. Timings include codec file I/O and omit model training. Treat individual timing samples as indicative. The graphs show measured operating points. nearest_rates.csv pairs each fixed point with the closest measured alternative for the same image and reports the achieved bitrate gap. Use Within10Pct to select pairs within the stated tolerance and compare their PSNR and SSIM. Some operating points have no close match. Results depend on texture, size and rate.
