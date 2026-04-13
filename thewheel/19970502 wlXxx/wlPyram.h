// wlPyram.h  Copyright (C) 1997  DG Lane

#ifndef _wlPyram_h_
#define _wlPyram_h_

#include "wlSignal.h"

class wlPyramid {
	public:
		wlPyramid(wlSignal *fromSig, int levels = 5);
	   ~wlPyramid();
	    
	    wlSignal *original();
	    void      update();
	    
	public:
	    int        l;     // number of levels
		wlSignal **g;
		wlSignal **dg;
		wlSignal **ddg;

		static int    kernelTap;
		static float *gKernel;
		static float *dgKernel;
		static float *ddgKernel;
		static void   initKernels();
};

#endif
