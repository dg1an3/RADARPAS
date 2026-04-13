// wlFrame.h  Copyright (C) 1996  DG Lane
// theWheel View module Frame class -- main window class for the application

#ifndef _WLFRAME_H_
#define _WLFRAME_H_
                    
#include "wlChild.h"

class wlFrame : public CMDIFrameWnd {
public:
	wlFrame();
	virtual ~wlFrame();
	DECLARE_DYNAMIC(wlFrame);
	
	BOOL OnCommand(UINT wParam, LONG lParam);

	// WlDocDB *map;		// The map associated with the frame
	// CObList views;		// List of WlVChild
	wlChild *onlySon;	 	// Single child for test purposes
	
	//{{AFX_MSG(wlFrame)
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP();
	
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif
};

#endif
