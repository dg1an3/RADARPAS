// wlSignal.h  Copyright (C) 1997  DG Lane

#ifndef _wlSignal_h_
#define _wlSignal_h_

class wlSignal {
	public:
		wlSignal();
		wlSignal(wlSignal *parent);
	   ~wlSignal();
	   
		void addSample(float value);
		void decimate();
		void convolve(float *kernel);
		
	public:
		long   t0;		// s[0] is sample at time t0
		long   rate;	// in msec/sample
		float *s;		// data
		long   numSamples;	// samples collected so far
		
		static int maxSamples;
		static int kernelTap;
};

#endif
