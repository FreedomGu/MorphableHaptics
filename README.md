# MorphableHaptics
 The Morphable Haptics Texture based on PCA is a GitHub repository that contains code and datasets related to haptic texture modeling and synthesis using Principal Component Analysis (PCA). The repository provides an implementation of the PCA-based approach for modeling and synthesizing haptic textures, which can be used for haptic feedback in various applications such as virtual reality and robotics.



The "modeling.py" file in this repository generates AR features based on force and speed inputs (force: 0-2, speed: 0-200), using 100 pre-defined haptic textures. The alpha parameter can be adjusted to create different haptic textures. A target texture can also be provided for debugging purposes. The target texture can be compressed and then reconstructed using PCA to test the effectiveness of the PCA method. If PCA works correctly, the alpha parameter can be adjusted to modify the texture (AR features) of the target texture.

To use this program, simply run the "modeling.py" script and provide the force and speed inputs. You can also adjust the alpha parameter to create different haptic textures. A target texture can be provided to test the effectiveness of PCA compression and reconstruction. Please note that the code is written in Python and requires the ```scikit-learn``` library.

This program can be useful for researchers and developers interested in haptic texture modeling and synthesis using PCA, and can be used as a starting point for developing new applications and techniques in this field. Please refer to the documentation and comments in the code for more information on how to use this program.
