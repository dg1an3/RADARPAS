// wlFrameView.h  Copyright (C) 1996, 97  DG Lane

#ifndef _wlFrameView_h_
#define _wlFrameView_h_
                    
#include "wlChildV.h"

#define numChildren 8

class wlFrameView : public CMDIFrameWnd {
		wlChildView *child[numChildren];
		double totArea;

public:
		wlFrameView();
		DECLARE_DYNAMIC( wlFrameView );

		wlChildView *getChild( int number ) { return child[number]; }		
		void setChild( wlChildView *newChild );
		double getTotalArea() { return totArea; }
		void dTotalArea( double delta ) { totArea += delta; }

		virtual ~wlFrameView();

#ifdef _DEBUG
		virtual void AssertValid() const;
		virtual void Dump( CDumpContext& dc ) const;
#endif

		//{{AFX_MSG(wlFrameView)
		afx_msg int OnCreate( LPCREATESTRUCT lpCreateStruct );
		//}}AFX_MSG
		DECLARE_MESSAGE_MAP();
};

#endif
