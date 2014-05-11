from decaf.scripts.imagenet import DecafNet
from skimage import io
import numpy as np
import scipy.io as sio
import os
import sys

if len(sys.argv) != 5:
    print "Usage ", sys.argv[0], "<model_root_dir> <image_dir> <output_feature_path> <num_imgs>"
    exit(1)

model_root = sys.argv[1]
net = DecafNet(model_root + 'imagenet.decafnet.epoch90', model_root + 'imagenet.decafnet.meta')
img_dir = sys.argv[2]
feature_path = sys.argv[3]
NUM_IMGS = int(sys.argv[4])
FEATURE_DIM = 4096 #fc6_cudanet_out's dimension

features = np.zeros((NUM_IMGS,FEATURE_DIM))
for i in range(NUM_IMGS):
    filename = img_dir + "/%05d.jpg"  %(i+1)
    if os.path.exists(filename):
        sys.stdout.write("Extracting DeCAF feature from image %d\n" %(i+1))
        img = io.imread(filename)
        net.classify(img, center_only=True)
        features[i,:] = net.feature('fc6_cudanet_out')

sio.savemat(feature_path,{'features':features})



