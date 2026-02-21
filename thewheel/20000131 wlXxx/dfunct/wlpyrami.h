// wlPyrami.h  Copyright (C) 1997  DG Lane

#ifndef _wlPyrami_h_
#define _wlPyrami_h_

class wlPyramid {
	public:
		wlPyramid(wlSignal *fromSig, unsigned levels = 5);
	   ~wlPyramid();
	    
	    wlSignal *original();
	    void      update();
	    
	    wlSignal *gauss(unsigned level);
	    wlSignal *dgauss(unsigned level);
	    wlSignal *lap(unsigned level);

	public:
	    unsigned levels;
		wlSignal *g;
		wlSignal *dg;
		wlSignal *l;
		
		static float *gaussKernel;
		static float *dgaussKernel;
		static float *lapKernel;
};

wlPyramid::gaussKernel = NULL;
wlPyramid::dgaussKernel = NULL;
wlPyramid::lapKernel = NULL;

#endif
