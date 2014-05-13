
#include "config.h"
#include <mex.h>

extern poselets_config
get_global_config()
{
  poselets_config config;
  mxArray*mx_config;

#define config_field(name, elts) \
  {#name, elts, offsetof(poselets_config,name), false}
#define config_logic(name) \
  {#name, 1, offsetof(poselets_config,name), true}

  struct { char const* name; int elts; int offset; bool islogical; }
  config_fields[] = {
    // Feature Parameters
    config_field(HOG_CELL_DIMS, 3),
    config_field(NUM_HOG_BINS, 3),
    config_field(HOG_WTSCALE, 1),
    config_field(HOG_NORM_EPS, 1),
    config_field(HOG_NORM_EPS2, 1),
    config_field(HOG_NORM_MAXVAL, 1),
    {0,0}};

  mx_config = mexGetVariable ("global", "config");

  for (int i = 0; config_fields[i].name; i++)
    {
      mxArray const *tmp = mxGetField (mx_config, 0, config_fields[i].name);
      double *field = (double*)(((char*)&config)+config_fields[i].offset);

      if (config_fields[i].islogical){
        *field = (double) mxGetLogicals(tmp)[0];
      }
      else {
        for (int f = 0; f < config_fields[i].elts; f++){
          field[f] = mxGetPr(tmp)[f];
        }
      }
    }

  return config;
}
