import numpy as np
import matplotlib.pyplot as plt

img = np.fromfile("image_output.raw", dtype=np.uint8)
#img = img.reshape((512, 512))  set correct size

plt.imshow(img, cmap='gray')
plt.show()
