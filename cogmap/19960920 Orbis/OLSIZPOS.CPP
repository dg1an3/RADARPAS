void ItemView::Move(int dx, int dy) {
	GetWindowRect(&bound);
	GetParent()->ScreenToClient(&bound);
	bound.OffsetRect(dx, dy);
	SetWindowPos(&wndTop,
		bound.left, bound.top,
		bound.right - bound.left, 
		bound.bottom - bound.top,
		SWP_NOZORDER);
	x += dx;
	y += dy;
}      // ItemView::Move

void ItemView::Inflate(int dx, int dy) {
	GetWindowRect(&bound);
	GetParent()->ScreenToClient(&bound);
	bound.InflateRect(dx, dy);
	SetWindowPos(&wndTop,
		bound.left, bound.top,
		bound.right - bound.left, 
		bound.bottom - bound.top,
		SWP_NOZORDER);
	size = (bound.right - bound.left)*(bound.bottom - bound.top);
}	// ItemView::Inflate

// #define PI 	(atan(1.0))
#define SINK_SIGMA 	200

double gauss(double x, double y, double s) { 
	return exp(-(x*x + y*y) / (s * s) ) /
			(sqrt(2 * PI) * s);
}	// gauss

double ItemView::dEdx() {
	double dEdx = 0.0;
	double xi = (double)xpos();
	double yi = (double)ypos();
	double si =  (double)getSize();	
	OrbFrame *parent = (OrbFrame *)GetParent();
	ASSERT(parent->IsKindOf(RUNTIME_CLASS(OrbFrame)));
	for (POSITION pos = parent->views.GetHeadPosition(); pos != NULL;) {
		ItemView *withItem = (ItemView *)parent->views.GetNext(pos);
		if (withItem != this) {
			double xo = (double)withItem->xpos();
			double yo = (double)withItem->ypos();
			double so =  (double)withItem->getSize();	
			dEdx += -2 * (xi - xo) * gauss(xi - xo, yi - yo, so) / 
							  (so * so);
		}	// if
	}	// for
	dEdx -=  gauss(xi - 400, yi - 250, SINK_SIGMA) * (-2 * (xi - 400)) /
							      ((double)SINK_SIGMA * SINK_SIGMA);
	return dEdx;
}	// ItemView::dEdx

double ItemView::dEdy() {
	double dEdy = 0.0;
	double xi = (double)xpos();
	double yi = (double)ypos();
	double si =  (double)getSize();
	OrbFrame *parent = (OrbFrame *)GetParent();
	for (POSITION pos = parent->views.GetHeadPosition(); pos != NULL;) {
		ItemView *withItem = (ItemView *)parent->views.GetNext(pos);
		if (withItem != this) {
			double xo = (double)withItem->xpos();
			double yo = (double)withItem->ypos();
			double so =  (double)withItem->getSize();	
			dEdy += -2 * (yi - yo) * gauss(xi - xo, yi - yo, so) / 
							   (so * so);
		}	// if
	}	// for
	dEdy -= gauss(xi - 400, yi - 250, SINK_SIGMA) * (-2 * (yi - 250)) /
							     ((double)SINK_SIGMA * SINK_SIGMA);
	return dEdy;
}	// ItemView::dEdy

double ItemView::dEds() {
	double dEds = 0.0;
	double xi = (double)xpos();
	double yi = (double)ypos();
	double si =  (double)getSize();	
	OrbFrame *parent = (OrbFrame *)GetParent();
	for (POSITION pos = parent->views.GetHeadPosition(); pos != NULL;) {
		ItemView *withItem = (ItemView *)parent->views.GetNext(pos);
		if (withItem != this) {
			double xo = (double)withItem->xpos();
			double yo = (double)withItem->ypos();
			dEds += gauss(xo - xi, yo - yi, si) * ( 1 + ((xo - xi) * (xo - xi) + (yo - yi) * (yo - yi)) / 
													            (si * si) );
		}	// if
	}	// for
	dEds += (double)activation - 2.0*si;
	return dEds;
}	// ItemView::dEds

int ItemView::UpdateSizePos() {
	double dx = dEdx() * 1e+5;
	double dy = dEdy() * 1e+5;
	double ds = dEds();
	TRACE("dx = %10.10f  dy = %10.10f  ds = %10.10f\n", dx, dy, ds);
	if (dEds() > 0.0)
		Inflate(1, 1);
	else if (dEds() < 0.0)
		Inflate(-1, -1);
	if (fabs(dx) > 1.0)
		Move((int)-dx, 0);
	else if (rand() < abs((int)(dx*RAND_MAX)))
		Move((dx > 0.0) ? -1 : 1, 0);
	if (fabs(dy) > 1.0)
		Move(0, (int)-dy);
	else if (rand() < abs((int)(dx*RAND_MAX)))
		Move(0, (dy > 0.0) ? -1 : 1);
	// Move( (dx > 0.0) ? -1 : 1, (dy > 0.0) ? -1 : 1);
	// char *s = ((TextItem *)item)->title.GetBuffer(40);
	// TRACE("Item %s activation = %i  size = %i\n", s, activation, getSize());
	return 0;
	// returns items energy
}	// ItemView::UpdateSizePos

