// wlSpring.cpp  Copyright (C) 1996  DG Lane

#include "stdafx.h"
#include <math.h>
#include "wlSpring.h"
                            
void 
calcParams( double kSpring,  double kFriction,
		double xInit,    double dxdtInit,
	      double *r1,      double *r2,
	      double *c1,      double *c2 )
{
	double det;
	det = kFriction * kFriction - 4 * kSpring;
	ASSERT(det > 0.0);
	det = sqrt(det);
	
	*r1 = - (kFriction - det) / 
	               2.0;
	*r2 = - (kFriction + det) / 
	               2.0;
	
	*c1 = (dxdtInit - xInit * *r2) /
                   (*r1 - *r2);
	*c2 = (dxdtInit - xInit * *r1) /
	             (*r2 - *r1);
}

wlSpring::wlSpring( double kSpring,  double kFriction,
			  long   timeInit,
			  double xInit,    double dxdtInit )
{
	ks = kSpring;
	kf = kFriction;
	t0 = timeInit;
	x0 = xInit;
	dxdt0 = dxdtInit;
	calcParams(ks, kf, x0, dxdt0, 
		&r1, &r2, &c1, &c2);
}

wlSpring::~wlSpring()
{
}

void 
wlSpring::eval( long t, double *x, double *dxdt ) 
{
	double term1 = c1 * exp(r1 * (double)(t - t0));
	double dterm1dt = term1 * r1;
	double term2 = c2 * exp(r2 * (double)(t - t0));
	double dterm2dt = term2 * r2;
	*x = term1 + term2;
	*dxdt = dterm1dt + dterm2dt;
}

void
wlSpring::reset( long timeInit,  double xInit )
{
	eval(timeInit, &x0, &dxdt0);
	t0 = timeInit;
	x0 = xInit;
	calcParams(ks, kf, x0, dxdt0, 
		&r1, &r2, &c1, &c2);
}
