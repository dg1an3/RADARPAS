// wlFrameWnd.h  Copyright (C) 1996, 97  DG Lane

#ifndef _wlFrameWnd_h_
#define _wlFrameWnd_h_

#include "wlView.h"

#define optArea (600.0 * 800.0/40.0)
#define GET_PARENT( x ) \
		wlFrameWnd *x = (wlFrameWnd *)::AfxGetApp()->m_pMainWnd
		
class wlFrameWnd : public CMDIFrameWnd  {

		CMapPtrToPtr childList;
		POSITION atChild;
		CMapPtrToPtr viewList;
		POSITION atView;
		double totArea;
		UINT timerID;

public:
		wlFrameWnd();
		
		DECLARE_DYNAMIC( wlFrameWnd );

		virtual ~wlFrameWnd();

		CMapPtrToPtr& getChildList() { return childList; }
		CMapPtrToPtr& getViewList() { return viewList; }
		double getAreaDelta() { return totArea - optArea; }
		void dTotalArea( double delta ) { totArea += delta; }
    
    	wlView *createView(wlObject *forObject, int atX, int atY);
    	void promoteView(wlView *view, DWORD t);
    	void updateChildren(DWORD t, CPoint mouseAt );
    	void updateViews( DWORD t );
    	int updateNextView(wlView *view, DWORD t );
    	
#ifdef _DEBUG
		virtual void AssertValid() const;
		virtual void Dump( CDumpContext& dc ) const;
#endif

		//{{AFX_MSG(wlFrameWnd)
		afx_msg int OnCreate( LPCREATESTRUCT lpCreateStruct );
		afx_msg void OnTimer(UINT nIDEvent);
		//}}AFX_MSG
		DECLARE_MESSAGE_MAP();
};

#endif
