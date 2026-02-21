// Spring.h  Copyright (C) 1996 DG Lane

class Spring {
	Spring(long initT, double Kspring, double Kfric,
		double initx, double initdxdt, double initxf);
	~Spring() { }
	
	void eval(long t, double *x, double *dxdt);
	void SetXf(long initT, double initxf);
	void SetK(long initT, double Kspring, double Kfric);
	void calcR();
	void calcC();	// depends on r values

	// Member variables
	double ks, kf;		// constants
	long t0;			// initial conditions
	double x0, xf, dxdt0;	
	double c1, r1, c2, r2;  // coefficients
};  // Spring
