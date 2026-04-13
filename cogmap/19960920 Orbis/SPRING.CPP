// Spring.cpp  Copyright (C) 1996  DG Lane

#include "stdafx.h"
#include <math.h>
#include "Spring.h"

Spring::Spring(long initT, double Kspring, double Kfric,
		double initx, double initdxdt, double initxf) {
	ks = Kspring;
	kf = Kfric;
	t0 = initT;
	x0 = initx;
	dxdt0 = initdxdt;
	xf = initxf;
	calcR();	// calculate the exponential coefficients
	calcC();	// calculate the coefficients
}  // Spring::Spring
	
void Spring::eval(long t, double *x, double *dxdt) {
	double term1 = c1*exp(r1*(double)(t-t0));
	double dterm1dt = term1*r1;
	double term2 = c2*exp(r2*(double)(t-t0));
	double dterm2dt = term2*r2;
	*x = term1 + term2 + xf/ks;
	*dxdt = dterm1dt + dterm2dt;
}  // Spring::eval

void Spring::SetXf(long initT, double initxf) {
	eval(initT, &x0, &dxdt0);
	t0 = initT;
	xf = initxf;
	calcC();
}  // Spring::SetXf

void Spring::SetK(long initT, double Kspring, double Kfric) {
	eval(initT, &x0, &dxdt0);
	t0 = initT;
	ks = Kspring;
	kf = Kfric;
	calcR();
	calcC();
}  // Spring::SetK

void Spring::calcR() {
	double det = kf*kf - 4*ks;
	ASSERT(det >= 0.0);
	det = sqrt(det);
	r1 = -(kf-det)/2;
	r2 = -(kf+det)/2;
}  // Spring::calcR

void Spring::calcC() {
	c1 = (dxdt0 - (x0-xf/ks)*r2) / (r1 - r2);
	c2 = (dxdt0 - (x0-xf/ks)*r1) / (r2 - r1);
}  // Spring::calcC
