// wlChildW.h  Copyright (C) 1996, 97 DG Lane
/////////////////////////////////////////////////////////////////

#ifndef _wlChildW_h_
#define _wlChildW_h_

#include "wlView.h"

class wlSpring  {

		// parameters
		double k_s, k_f;
				
		// initial values
		double y_f, t_0;
		
		// general solution
		double alpha, beta;
		
		// specific solution
		double c_a, c_b;
		
public:
		wlSpring( DWORD t0,  double ks, double kf, double yi, double yf, double dyi_dt );
		~wlSpring() { }

		void computeAlphaBeta();
		void computeCaCb( double yi, double dyi_dt );
		
		
		double y( DWORD t );
		double dydt( DWORD t );
		
		void reset( DWORD t, double y_f );
};


class wlChildWnd : public CMDIChildWnd  {

//  Member variables
		// float           myWidth;
		wlSpring *w, *x, *y;
		wlView    *myView;
		CDC        *compDC;
		CBitmap *compBitmap; 
public:
		UINT          timerID;
		DWORD   lastUpdate;

public:
		wlChildWnd();
		wlChildWnd( wlView *forView, DWORD t );
		
		DECLARE_DYNCREATE(wlChildWnd);
		
		void PostNcDestroy() { }
   		virtual ~wlChildWnd();

		wlView *getView() { return myView; }
		void setView(wlView *toView);
		double getX( DWORD t ) { return myView->getX( t ); }		
		double getY( DWORD t ) { return myView->getY( t ); } 		
		double getWidth( DWORD t ) { return myView->getWidth( t ); }
		void setWidth(double width);
		
		void gestureToView( DWORD t, CPoint mouseAt );
		void bungeeUpdate( DWORD t );
		
		BOOL Draw(CDC* pDC, LPCRECT lpBounds,         
   				LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);

		//{{AFX_MSG(wlChildWnd)
		afx_msg void OnPaint();
		afx_msg void OnTimer(UINT nIDEvent);
		afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
		//}}AFX_MSG
		DECLARE_MESSAGE_MAP()
};

#endif
