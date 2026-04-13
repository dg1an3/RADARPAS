// wlView.h  Copyright (C) 1996, 97 DG Lane

#ifndef _wlView_h_
#define _wlView_h_

#include "wlObject.h"

// wlView
//		Base class for all view classes (object renderers).
//		Contains mapping engine.
/////////////////////////////////////////////////////////////////////////

class wlView : public wlObject  {	

// Attributes
		wlObject   *myObject;
		double       	t0;
		double          myX, dX, myY, dY;
		double          myWidth, dWidth;
		POSITION nextNeighbor;
		// int state; // 0 = demoted, 1 = promoted

public:
		wlView();
		wlView(wlObject *ofObject, int atX, int atY);

		DECLARE_DYNCREATE(wlView);

   		~wlView();
		BOOL removeReferences( CMapPtrToPtr& );

// Access and update
		wlObject *getObject() { return myObject; }
		double getX( DWORD t ) { return myX; }
		double getY( DWORD t ) { return myY; }
		double getWidth( DWORD t ) { return myWidth; }		
		void setWidth(DWORD t, double width) { myWidth = width; }

		void addLink(wlView *newLink);
		
		void spacerField( DWORD t, wlView *sibling, double *dX, double *dY );
		void linkField( DWORD t, wlObjectLink *link, double *dX, double *dY );
		void sinkField( DWORD t, double sinkX, double sinkY, double *dX, double *dY );
		void pullProp( DWORD t, wlObjectLink *link );
		void normalize( DWORD t );
				
		void update( DWORD t, int sinkX, int sinkY );

// Rendering
		BOOL draw( CDC* pDC, LPCRECT lpBounds);
};

#endif
