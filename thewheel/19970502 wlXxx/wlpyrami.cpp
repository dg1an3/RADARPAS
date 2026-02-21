// wlPyramid.cpp
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
		static float *gaussKernel;
		static float *dgaussKernel;
		static float *lapKernel;
				
	    unsigned levels;
		wlSignal *g;
		wlSignal *dg;
		wlSignal *l;
};

