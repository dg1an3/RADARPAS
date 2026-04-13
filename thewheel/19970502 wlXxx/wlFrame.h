// wlFrameV.h  Copyright (C) 1996, 97  DG Lane

#ifndef _wlFrameView_h_
#define _wlFrameView_h_
                    
#include "wlChildView.h"
// #include "wlSignal.h"

#define numChildren 8

class wlFrameView : public CMDIFrameWnd {
public:
		wlChildView *son[numChildren];
		double totSize;
		// wlSignal	mx, my;
	
public:
		wlFrameView();
		DECLARE_DYNAMIC( wlFrame );

		void trackMouse( long t, int mx, int my );

		//{{AFX_MSG(wlFrame)
		afx_msg int OnCreate( LPCREATESTRUCT lpCreateStruct );
		//}}AFX_MSG
		DECLARE_MESSAGE_MAP();

#ifdef _DEBUG
		virtual void AssertValid() const;
		virtual void Dump( CDumpContext& dc ) const;
#endif

		virtual ~wlFrameView();
};

#endif
