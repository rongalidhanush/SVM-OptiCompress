# Installation and data
The supported baseline for this delivery is MATLAB R2026a on Windows. Use Statistics and Machine Learning Toolbox for fitcecoc and Optimization Toolbox for quadprog. The code calls Image Processing Toolbox's ssim when available for images at least 11 pixels along each axis. An included Gaussian-window implementation handles smaller images and installations without that function. The DCT matrix, padding and block features use base MATLAB. No network or GPU is required.

1. Extract the entire archive. Make the folder containing setup.m the Current Folder.
2. Run `setup` to add paths, check core dependencies, create output directories and generate any missing sample PNGs.
3. Run `run_project`. A bundled model loads automatically. If missing, the first SVM action trains a replacement.
4. Run `run_tests` for the regression suite or `run_demo` to regenerate the example outputs. Both can write to the project folder. Training replaces the saved model and the demo replaces the named example results.

## Additional images
Place training sources in datasets/training and held-out sources in datasets/testing. Use PNG, JPEG, BMP or TIFF files. Keep related crops, near-duplicates and frames from the same scene entirely within one split. train_svm_model reads the first image in each supported file. It concatenates block features in memory. Resize unusually large training photographs before adding them. Training requires examples of all three labels. Run train_svm_model after changing the dataset, then restart the app or use its training button. The batch comparison uses PNGs in datasets/testing. The GUI accepts an individual image independently of that dataset.

## Decode a saved file
In a fresh MATLAB session with the project as Current Folder:

```matlab
addpath(genpath('src'))
[img, classes] = decompress_image('results/compressed/scene_09.soc');
imwrite(img, 'decoded.png')
```

This path needs only the codec source and the .soc file. Dimensions, quantizer settings and class assignments come from the stream. In the app, select **Open compressed file** and then **Decompress**. Reference quality scores appear only for a stream paired with its original in the current session.

For training errors, run `which fitcecoc -all` and `which quadprog -all` to check toolbox paths. If loading a model from another MATLAB release fails, run train_svm_model from the project root to rebuild it.
