PANDA code
=============
PANDA (Pose-Aligned Networks for Deep Attibute) is an attribute classification system using deep neural nets. This work is created by Ning Zhang, Manohar Paluri, Marc'Aurelio Ranzato, Trevor Darrell and Lubomir Bourdev.

### Citing this work
If you are using this code for your research, please cite the following paper:

    @inproceedings{ZhangCVPR14,
        Author = {Zhang, Ning and Paluri, Manohar and Rantazo, Marc'Aurelio and Darrell, Trevor and Bourdev, Lubomir},
        Title = {PANDA: Pose Aligned Networks for Deep Attribute Modeling},
        Booktitle = {Conference on Computer Vision and Pattern Recognition (CVPR)},
        Year = {2014}
    }

### Prerequisites
0. **Caffe**
  - Download caffe from Ning Zhang's caffe fork https://github.com/n-zhang/caffe
  - Put caffe directory inside pose-aligned-deep-networks/

0. **Poselet Detection**
  - Download poselet detection code from http://www.cs.berkeley.edu/~lbourdev/poselets/
  - Run poselet detection on your own data if needed.
  - Substract poselet_id by 1 inside phits.

0. **MATLAB**
  - The software is tested on MATLAB R2012b and R2012a versions.

### Usage
  - run.m is the main function to reproduce the results on Berkeley Attribute Dataset in the paper. The dataset can be downloaded from http://www.cs.berkeley.edu/~lbourdev/poselets/.
  - All the cached features can be found at http://www.eecs.berkeley.edu/~nzhang/codes/panda_caches.tgz.

### License
This software is under BSD License, please refer to LICENSE file. We also provide an additional patent grant.

### Bug report
If you have any issues running the codes, please report issues on github page. If you want to contribute to the codes, please follow the instructions in CONTRIBUTING.md. If you have any questions about the paper, please contact Ning Zhang (nzhang@eecs.berkeley.edu).


