
#ifndef NO_OMP
#include <omp.h>
#endif

#include <mex.h>
#include <math.h>
#include <string.h>
#include <sys/time.h>

#include "config.h"

static double pi = 3.14159265358979;

static double timestamp(){
  struct timeval tv;
  gettimeofday (&tv, 0);
  return tv.tv_sec + 1e-6*tv.tv_usec;
}

void compute_hog (mxArray*& mxhog, mxArray*& mxsampx, mxArray*& mxsampy,
                  float const *img0, int H, int W, int C);


extern "C" void
mexFunction (int nl, mxArray *pl[], int nr, mxArray const *pr[])
{
  if ((nr != 1) || (mxGetClassID(pr[0])!=mxSINGLE_CLASS) ||
      (mxGetNumberOfDimensions(pr[0])!=3 && mxGetDimensions(pr[0])[2]!=3)) {
    mexErrMsgTxt(
      "[hog,samples_x,samples_y] = compute_hog_mex(img)\n"
      "  img: [H x W x 3] RGB image of float (single), range 0..255\n"
      "  hog: [HH x WW x 36] of double, hog cells\n"
      "  samples_x, samples_y: top left coords of each cell (starting from 0)\n");
    return;
  }

  mxArray const *mximg;
  mximg = pr[0];

  compute_hog (pl[0], pl[1], pl[2],
               (float const*) mxGetData(pr[0]),
               mxGetDimensions(pr[0])[0],
               mxGetDimensions(pr[0])[1],
               mxGetDimensions(pr[0])[2]);
}

template <typename T> static inline T max (T a, T b){
  return (a > b) ? a : b;
}

template <typename T> static inline T min (T a, T b){
  return (a > b) ? b : a;
}

void
compute_hog (
  mxArray*& mxhog, mxArray*& mxsampx, mxArray*& mxsampy,
  float const *img0, int H, int W, int C)
{
  int DEBUG=0;
  poselets_config config = get_global_config ();

  double ts;

  if (DEBUG>0)
    ts = timestamp();

  float var2[2];
  for (int i = 0; i < 2; i++){
    var2[i] = config.HOG_CELL_DIMS[i] / (2*config.HOG_WTSCALE);
    var2[i] = var2[i]*var2[i]*2;
  }

  float half_bin[3];
  for (int i = 0; i < 3; i++)
    half_bin[i] = config.NUM_HOG_BINS[i]/2;

  float cenBand[3];
  for (int i = 0; i < 3; i++)
    cenBand[i] = config.HOG_CELL_DIMS[i]/2;

  float bandwidth[3];
  for (int i = 0; i < 3; i++)
    bandwidth[i] = config.HOG_CELL_DIMS[i] / config.NUM_HOG_BINS[i];


  int num_cells[2];
  num_cells[0] = floor((W-2)/bandwidth[0]) - config.NUM_HOG_BINS[0]+1;
  num_cells[1] = floor((H-2)/bandwidth[1]) - config.NUM_HOG_BINS[1]+1;

  int num_angles = config.NUM_HOG_BINS[2];
  float aspan = bandwidth[2];
  float *angles = (float*) calloc (num_angles, sizeof(*angles));

  for (int i = 0; i < num_angles; i++)
    angles[i] = 180.0 * (i+1.0-0.5) / num_angles;

  float *img = (float*) calloc (W*H*C, sizeof(*img));

  for (int x = 0; x < W; x++){
    for (int y = 0; y < H; y++){
      for (int c = 0; c < C; c++){
        img[y + H*(x + W*c)] = sqrtf(img0[y + H*(x + W*c)]);
      }
    }
  }

  if (DEBUG>0) {
    mexPrintf("%f s\n", timestamp()-ts);
    ts = timestamp();
  }

  float *_mag_ = (float*) calloc (W*H, sizeof(*_mag_));
#define mag(y,x) _mag_[(int)((y) + H*((x)))]

  float *_ohist_ = (float*) calloc (W*H*num_angles, sizeof(*_ohist_));
#define ohist(y,x,a) _ohist_[(int)((y)+H*((x)+W*((a))))]

#pragma omp parallel for
  for (int x = 1; x < W-1; x++){
    for (int y = 1; y < H-1; y++)
    {
      float m = -1e6, o = 0;

      for (int c = 0; c < C; c++)
      {
        float gx, gy, mc, oc;

        gx = - img[y + H*(x-1 + W*c)] + img[y + H*(x+1 + W*c)];
        gy = - img[y-1 + H*(x + W*c)] + img[y+1 + H*(x + W*c)];

        mc = gx*gx + gy*gy;
        oc = atan2f(gy,gx);

        if (mc > m){
          m = mc;
          o = oc;
        }
      }

      mag(y,x) = sqrtf(m);
      if ((o = o * (180.0/pi) + 180.0f) > 180.0f)
        o = o-180.0f;

      float ori = floorf(o);

      for (int a = 0; a < num_angles; a++){
        float oh = fabsf(angles[a] - ori);

        oh = (1.f/aspan)*(max(0.f,aspan-oh)+max(0.f,aspan-(180.f-oh)));

        ohist(y,x,a) = oh;
      }
    }
  }
    free(img);

  mag(0,0) = mag(1,1);
  mag(0,W-1) = mag(1,W-2);
  mag(H-1,0) = mag(H-2,1);
  mag(H-1,W-1) = mag(H-2,W-2);
  for (int y = 1; y < H-1; y++){
    mag(y, 0) = mag(y,1);
    mag(y, W-1) = mag(y,W-2);
  }
  for (int x = 1; x < W-1; x++){
    mag(0, x) = mag(1,x);
    mag(H-1, x) = mag(H-2,x);
  }

  for (int a = 0; a < num_angles; a++)
  {
    ohist(0,0,a) = ohist(1,1,a);
    ohist(0,W-1,a) = ohist(1,W-2,a);
    ohist(H-1,0,a) = ohist(H-2,1,a);
    ohist(H-1,W-1,a) = ohist(H-2,W-2,a);

    for (int y = 1; y < H-1; y++){
      ohist(y, 0,a) = ohist(y,1,a);
      ohist(y, W-1,a) = ohist(y,W-2,a);
    }
    for (int x = 1; x < W-1; x++){
      ohist(0, x,a) = ohist(1,x,a);
      ohist(H-1, x,a) = ohist(H-2,x,a);
    }
  }

    if (DEBUG>0) {
      mexPrintf("%f s\n", timestamp()-ts);
      ts = timestamp();
    }


  /*debug_array("mag", 1, _mag_, H, W);
  debug_array("ori", 1, _ori_, H, W);
  debug_array("ohist", 1, _ohist_, H, W, (int)num_angles);*/

  float leftover[2];
  leftover[0] = floorf (0.5f*(W - (num_cells[0]-1)*bandwidth[0]
                              - config.HOG_CELL_DIMS[0]));
  leftover[1] = floorf (0.5f*(H - (num_cells[1]-1)*bandwidth[1]
                              - config.HOG_CELL_DIMS[1]));

  float *samples_x, *samples_y;

  {size_t dims[2]; dims[0] = 1;
   dims[1] = num_cells[0];
   mxsampx  = mxCreateNumericArray (2, dims, mxSINGLE_CLASS, mxREAL);
   samples_x = (float*) mxGetData (mxsampx);

   dims[1] = num_cells[1];
   mxsampy  = mxCreateNumericArray (2, dims, mxSINGLE_CLASS, mxREAL);
   samples_y = (float*) mxGetData (mxsampy);}

  //float *samples_x = (float*) calloc (num_cells[0], sizeof(*samples_x));
  for (int i = 0; i < num_cells[0]; i++)
    samples_x[i] = i*bandwidth[0] + leftover[0];

  //float *samples_y = (float*) calloc (num_cells[1], sizeof(*samples_y));
  for (int i = 0; i < num_cells[1]; i++)
    samples_y[i] = i*bandwidth[1] + leftover[1];

    if (DEBUG>0) {
      mexPrintf("%f s\n", timestamp()-ts);
      ts = timestamp();
    }


  int hs0, hs1, hs2, hs3, hs4;
  float *_hog_;

#define hog(i0, i1, i2, i3, i4) \
   _hog_[(int)((i0)+hs0*((i1)+hs1*((i2)+hs2*((i3)+hs3*((i4))))))]

  hs0 = num_cells[1];
  hs1 = num_cells[0];
  hs2 = config.NUM_HOG_BINS[2];
  hs3 = config.NUM_HOG_BINS[0];
  hs4 = config.NUM_HOG_BINS[1];

  {size_t dims[5] =  {hs0,hs1,hs2,hs3,hs4};
   mxhog = mxCreateNumericArray (5, dims, mxSINGLE_CLASS, mxREAL);}

  _hog_ = (float * __restrict__) mxGetData (mxhog);
  memset (_hog_, 0, hs0*hs1*hs2*hs3*hs4*sizeof(float));

  int nbins[3];
  for (int i = 0; i < 3; i++)
    nbins[i] = config.NUM_HOG_BINS[i];

#pragma omp parallel
  for (int x = 0; x < config.HOG_CELL_DIMS[0]; x++){
    for (int y = 0; y < config.HOG_CELL_DIMS[1]; y++)
    {
      float xx = (x - 0.5f*config.HOG_CELL_DIMS[0]);
      float yy = (y - 0.5f*config.HOG_CELL_DIMS[1]);
      float w = expf( -(xx*xx / var2[0]) -(yy*yy / var2[1]));

      float pt[2], fr[2];
      int fl[2], cl[2];
      pt[0] = half_bin[0] - 0.5f + (x+0.5f-cenBand[0]) / bandwidth[0];
      pt[1] = half_bin[1] - 0.5f + (y+0.5f-cenBand[1]) / bandwidth[1];

      for (int i = 0; i < 2; i++){
        fl[i] = floorf(pt[i]);
        fr[i] = pt[i]-fl[i];
        cl[i] = fl[i] + 1;
      }

      for (int a = 0; a < num_angles; a++){
#pragma omp for
        for (int j = 0; j < num_cells[0]; j++){
          for (int i = 0; i < num_cells[1]; i ++)
          {
            float smag = mag(samples_y[i]+y, samples_x[j]+x);
            float sori = ohist(samples_y[i]+y,samples_x[j]+x,a);
            float wt = smag * sori * w;

            if (fl[0] > -1 && fl[1] > -1){
              hog(i,j,a,fl[1],fl[0]) += wt*(1-fr[0])*(1-fr[1]);
            }

            if (fl[0] > -1 && cl[1] < nbins[1]){
              hog(i,j,a,cl[1],fl[0]) += wt*(1-fr[0])*fr[1];
            }

            if (cl[0] < nbins[0] && fl[1] > -1){
              hog(i,j,a,fl[1],cl[0]) += wt*fr[0]*(1-fr[1]);
            }

            if (cl[0] < nbins[0] && cl[1] < nbins[1]){
              hog(i,j,a,cl[1],cl[0]) += wt*fr[0]*fr[1];
            }
          }
        }
      }
    }
  }

    if (DEBUG>0) {
      mexPrintf("%f s\n", timestamp()-ts);
      ts = timestamp();
    }

  free (angles);
  free (_mag_);
  free (_ohist_);

  {size_t dims[2] =  {hs0*hs1,hs2*hs3*hs4};
  mxSetDimensions (mxhog, dims, 2);}
#undef hog
#define hog(i,j) _hog_[(i) + (hs0*hs1)*(j)]

  float *sumsqrd = (float*) calloc (hs0*hs1, sizeof(float));

#pragma omp parallel
{
#pragma omp for
  for (int i = 0; i < hs0*hs1; i++)
  {
    sumsqrd[i] = 0;
    for (int j = 0; j < hs2*hs3*hs4; j++)
      sumsqrd[i] += hog(i,j)*hog(i,j);

    sumsqrd[i] = sqrtf(sumsqrd[i]);
  }

#pragma omp for
  for (int j = 0; j < hs2*hs3*hs4; j++){
    for (int i = 0; i < hs0*hs1; i++){
      hog(i,j) /= (sumsqrd[i] + config.HOG_NORM_EPS*hs2*hs3*hs4);
      hog(i,j) = min(hog(i,j), (float)config.HOG_NORM_MAXVAL);
    }
  }

#pragma omp for
  for (int i = 0; i < hs0*hs1; i++)
  {
    sumsqrd[i] = 0;
    for (int j = 0; j < hs2*hs3*hs4; j++)
      sumsqrd[i] += hog(i,j)*hog(i,j);
    sumsqrd[i] = sqrtf(sumsqrd[i]);
  }

#pragma omp for
  for (int j = 0; j < hs2*hs3*hs4; j++){
    for (int i = 0; i < hs0*hs1; i++){
      hog(i,j) /= (sumsqrd[i] + config.HOG_NORM_EPS2);
    }
  }
}

  free (sumsqrd);

  {size_t dims[3] =  {hs0,hs1,hs2*hs3*hs4};
  mxSetDimensions (mxhog, dims, 3);}

    if (DEBUG>0) {
      mexPrintf("%f s\n", timestamp()-ts);
      ts = timestamp();
    }
}

