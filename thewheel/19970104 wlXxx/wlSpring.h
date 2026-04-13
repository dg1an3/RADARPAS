// wlSpring.h  Copyright (C) 1996 DG Lane

#ifndef _wlSpring_h_
#define _wlSpring_h_

class wlSpring 
{              
	public:
		wlSpring( double kSpring, double kFriction,
			long timeInit, double xInit, double dxdtInit );
	   ~wlSpring();

		void eval( long t, double *x, double *dxdt );
		void reset( long timeInit, double xInit );

    private:
		double ks, kf;		// constants
		long   t0;			// initial
		double x0, dxdt0;	//   conditions
		double r1, r2;		// roots
		double c1, c2;		// coefficients
};

#endif
