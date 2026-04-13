// wlChildView.h  Copyright (C) 1996, 97 DG Lane

#ifndef _wlChildView_h_
#define _wlChildView_h_

#include "wlObject.h"

class wlChildView : public CMDIChildWnd {
		wlObject *myObject;
		double myX, myY;
		double myWidth;
		CDC *compDC;
		CBitmap *compBitmap; 

	public:
		wlChildView();
		wlChildView(wlObject *ofObject);
		DECLARE_DYNCREATE(wlChildView);

		wlObject *getObject() { return myObject; }
		// const CPoint *getPosition { return myPosition; }
		// double getX() { return myX; }		void setX(double x);
		// double getY() { return myY; } 		void setY(double y);
		// double getWidth() { return myWidth; }		void setWidth(double width);

		void updatePos();                                                         
		void updateSize(CPoint mouseAt);
		
		BOOL Draw(CDC* pDC, LPCRECT lpBounds,         
   				LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);

		void PostNcDestroy() { }
   		virtual ~wlChildView();

		//{{AFX_MSG(wlChildView)
		afx_msg void OnPaint();
		//}}AFX_MSG
		DECLARE_MESSAGE_MAP()
};

#endif
