REAL dGaussdx(REAL x, REAL y, REAL sigma) {
	return EXP(-(x*x + y*y)/(2*sigma)) / (2*PI*sigma*sigma)
	    * -(2*x)/(2*sigma);
}   // dGaussdx

#define Rsigma 10000.0
#define Asigma 20000.0
#define kR 1.1e+11
#define kA 7e+11
#define kEnv 5e+12
#define kUsr 1e+13
#define kFric 0.08

void MapItem::dt(int timeslices) {
}	// MapItem::dt

/* REAL MapItem::sqrtSpeed() {	// sqrt of the speed of the object
	return sqrt(ABS(dwx) + ABS(dwy)); 
} */

	MapDoc *pDoc = (MapDoc *)GetDocument();
	REAL deltat = 1;
	REAL ddwx = 0.0, ddwy = 0.0;
	ddwx += ((REAL)rand()-(REAL)RAND_MAX/(REAL)2.0-(REAL)0.5)*pDoc->temp;
	ddwy += ((REAL)rand()-(REAL)RAND_MAX/(REAL)2.0-(REAL)0.5)*pDoc->temp; 
	ddwx -= dwx*kFric;
	ddwy -= dwy*kFric;
	REAL SumdRnidxn = 0.0, SumdRnidyn = 0.0;
	REAL SumdAnidxn = 0.0, SumdAnidyn = 0.0;
	POSITION pos2 = pDoc->GetStartPosition();
	int i = 0, at = 0;
	while (pos2 != NULL) {
		MapItem *item2 = (MapItem *)pDoc->GetNextItem(pos2);
		if (item2 != this) {
			SumdRnidxn += dGaussdx(wx-item2->wx,wy-item2->wy,Rsigma);
			SumdRnidyn += dGaussdx(wy-item2->wy,wx-item2->wx,Rsigma);	
			SumdAnidxn += corr[i]*dGaussdx(wx-item2->wx,wy-item2->wy,Asigma);
			SumdAnidyn += corr[i]*dGaussdx(wy-item2->wy,wx-item2->wx,Asigma);
		} else {
			at = i;
		}   // if
		i++;
	}	// while
	ddwx += -kR*SumdRnidxn+kA*SumdAnidxn+kEnv*dGaussdx(wx-400,wy-300,40000);
	ddwy += -kR*SumdRnidyn+kA*SumdAnidyn+kEnv*dGaussdx(wy-300,wx-400,40000);
	dwx += ddwx*deltat; 
	dwy += ddwy*deltat; 
	wx += dwx;
	wy += dwy; 
	lastUpdate = pDoc->t;
