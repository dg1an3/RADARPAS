// wlView.cpp  Copyright (C) 1996, 97 DG Lane
///////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include <math.h>

#include "wlFrameW.h"
#include "wlView.h"
#include "wlLookup.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

// wlView default constructor
///////////////////////////////////////////////

#define MIN(x, y) ((x) < (y) ? (x) : (y))
#define MAX(x, y) ((x) > (y) ? (x) : (y))


double
expFunc2( double x )  {
		return exp( x );
}

wlLookup *expTable2 = (wlLookup *)NULL;

void
createLookup( double min, double max ) {
		if (!expTable2)  {
/*				min = MIN(min, 0.1);
				max = MAX(max, 0.1); */
				expTable2 = new wlLookup( min, max, 0.05, &expFunc2 );
		}
}
	
wlView::wlView() : wlObject()  {

		myObject = (wlObject *)NULL;
		myX = 0;
		myY = 0;
		myWidth = 0;
		// state = 0;
		nextNeighbor = (POSITION)NULL;
		
		createLookup( -5.0, 0.1 );
}


// wlView constructor
/////////////////////////////////////

wlView::wlView(wlObject *ofObject, int atX, int atY) : wlObject()  {

		myObject = ofObject;
		myX = atX; // rand() % 600 + 100;
		myY = atY; // rand() % 400 + 100;
		myWidth = 1.0;
		// state = 0;
		nextNeighbor = (POSITION)NULL;

		createLookup( -5.0, 0.1 );
}


IMPLEMENT_DYNCREATE( wlView, CMDIChildWnd )


// wlView::addLink
//   Over-ride to automatically look up object to find link weight, or set to zero
//   if objects not linked
////////////////////////////////////////////////////////////////////////////////////////////////////////
void
wlView::addLink(wlView *toView)  {

		if (toView == this)
				return;
		wlObject *toObject = toView->getObject();
		wlObjectLink *objLink = toObject->getLinkByTarget(this->getObject());
		wlObjectLink *newLink = 
				new wlObjectLink(toView, (objLink) ? objLink->getWeight() : (float)0.0);
		wlObject::addLink(newLink);
}


// wlView destructor
///////////////////////////////////

wlView::~wlView()  {

		for (POSITION pos = getLinkStartPos(); pos != NULL;)  {
				wlObjectLink *nextLink = getNextLink(pos);
				if (nextLink)
						nextLink->getTarget()->delLink(this);
		}
}


// wlView::draw
/////////////////////////////
BOOL 
wlView::draw(CDC* pDC, LPCRECT lpBounds)  {
		int nextScaleHint;
		BOOL status = myObject->Draw(pDC, lpBounds, &nextScaleHint);
		return status;
}


 #define pi (3.14159265359)
 // #define pi (atan(1.0)*4.0)
#define sqrt2pi  (2.506628274631)

// #define gauss(x, s) (exp( -(x)*(x) / (2.0*(s)) ) / (sqrt(2.0 * pi )* (s))
double yMax = 0.0;
double yMin = 0.0;
double 
gauss( double x, double s)  { 
		double y =  -(x)*(x) / (2.0*(s)) ;
/*		if (y > yMax)  {
				TRACE( "yMax = %lf\n", y );
				yMax = y;
		}
		if (y < yMin) {
				TRACE("yMin = %lf\n", y );
				yMin = y;
		} */
//		return (exp(y) / (sqrt2pi*s));
		return (expTable2->value(y) / (sqrt2pi*s));
}

// #define negExpApprox(x) ( 1.0 / (1.0 + (x) + (x)*(x)/2.0 ) )
// #define gauss(x, s) ( negExpApprox( (x)*(x) / (2.0*(s)) ) / (sqrt2pi*(s)) )
// #define dgauss(x, s) ((-2*(x) / (2.0*(s))) * gauss(x, s))
double 
dgauss( double x, double s )  {
		return ((-2.0*(x) / (2.0*(s))) * gauss(x, s));
}


// wlView::spacerField
/////////////////////////////////////

#define spacerK (2.5e+7)

void
wlView::spacerField( DWORD t, wlView *sibling, double *dX, double *dY )  {	

		// repulsion field
		double sigma = sibling->getWidth( t )*24.0;
		// ASSERT(sigma >= 0.0);
		*dX += spacerK * dgauss(sibling->myX - myX, sigma) *
							gauss(sibling->myY - myY, sigma) * (/* sqrt(2.0 * pi ) */ sqrt2pi * (sigma));
		*dY += spacerK * gauss(sibling->myX - myX, sigma) * 
					 		dgauss(sibling->myY - myY, sigma) * (/* sqrt(2.0 * pi ) */ sqrt2pi * (sigma));
}

									
// wlView::linkField
/////////////////////////////////////

#define linkK (3.0e+7)

void
wlView::linkField( DWORD t, wlObjectLink *link, double *dX, double *dY )  {	

		// Weighted attraction field
		double weight = link->getWeight();
		wlView *sibling = (wlView *)link->getTarget();
		double sigma = sibling->getWidth( t )*30.0; 
		*dX -= weight * linkK * dgauss(sibling->myX - myX, sigma) *
				     		gauss(sibling->myY - myY, sigma) * (/* sqrt(2.0 * pi ) */ sqrt2pi * (sigma));
		*dY -= weight * linkK * gauss(sibling->myX - myX, sigma) *
					 		dgauss(sibling->myY - myY, sigma) * (/* sqrt(2.0 * pi ) */ sqrt2pi * (sigma));	
}


// wlView::sinkField
/////////////////////////////////////

#define sinkK (0.008)

void
wlView::sinkField( DWORD t, double sinkX, double sinkY, double *dX, double *dY )  {		

		*dX += sinkK * (sinkX/2.0 - myX);	// sink
		*dY += sinkK * (sinkY/2.0 - myY);	// sink
}

// wlView::pullProp
/////////////////////////////////////

void
wlView::pullProp( DWORD t, wlObjectLink *link )  {	

		// pull propagation
		wlView *sibling = (wlView *)link->getTarget();
		double  deltaWidth = 0.9 * link->getWeight() * sibling ->getWidth(t) / 
													getWidth(t);
		setWidth(t, getWidth(t) + deltaWidth);
		myX = getX(t) + (400.0 - getX(t))*deltaWidth/100.0;
		myY = getY(t) + (300.0 - getY(t))*deltaWidth/100.0;
}


//  wlView::normalize
/////////////////////////////

void
wlView::normalize( DWORD dt )  {
        
        GET_PARENT( parent );
		
		//  Compute current area
		// double area = myWidth*myWidth;
		
		//  Compute change in area based on total childWnd area
		double dWidth = 1.6e-7 * myWidth * parent->getAreaDelta();
		
		myWidth += -dWidth;
}		


// wlView::update
////////////////////////////////////

void 
wlView::update( DWORD t, int sinkX, int sinkY )  {

		if (rand() > RAND_MAX/3 ) 
				return;

		POSITION        pos;
		wlObjectLink *nextLink;
		wlView             *sibling;
		double                 dX = 0.0; 
		double                 dY = 0.0;
		
		for (pos = getLinkStartPos(); pos != NULL;)  {
				nextLink = getNextLink(pos);
				if (nextLink)  {
						sibling = (wlView *)nextLink->getTarget();  
						ASSERT(sibling);

						if ((fabs(sibling->getX(t) - getX(t)) < 300.0) &&
										(fabs(sibling->getY(t) - getY(t)) < 300.0))
								spacerField( t, sibling, &dX, &dY );
						if (nextLink->getWeight() > 0.0 )  {
								linkField( t, nextLink, &dX, &dY );
			 					pullProp( t, nextLink );
			 			}
			 	}
		}
		
		sinkField( t, (double)sinkX, (double)sinkY, &dX, &dY );
		
		myX += dX;
		myY += dY;
		
		if (!nextNeighbor)
				nextNeighbor = getLinkStartPos();
				
		nextLink = getNextLink( nextNeighbor );
		if (nextLink && (nextLink != (wlObjectLink *)0xcdcdcdcd))  {
				sibling = (wlView *)nextLink->getTarget();  
				sibling->update( t, sinkX, sinkY );
		}
}

BOOL wlView::removeReferences( CMapPtrToPtr& viewList ) {
	POSITION pos = viewList.GetStartPosition();
	while (pos) {
		wlView *view;
		wlObject *object;
		viewList.GetNextAssoc( pos, (void *&)object, 
			(void *&)view );
		view->delLink( this );
	}
	return TRUE;
}
