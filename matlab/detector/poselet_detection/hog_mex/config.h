
#ifndef poselet_config_h
#define poselet_config_h

struct poselets_config
{
// Feature Parameters
  double HOG_CELL_DIMS[3];
  double NUM_HOG_BINS[3];
  double HOG_WTSCALE;
  double HOG_NORM_EPS;
  double HOG_NORM_EPS2;
  double HOG_NORM_MAXVAL;
};

extern poselets_config get_global_config();

#endif
