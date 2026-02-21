// ItemView.h  Copyright (C) 1996  DG Lane

#ifndef ItemView_h
#define ItemView_h

#include "OrbItem.h"

class ItemView : public CMDIChildWnd {
public:
	ItemView();
	virtual ~ItemView();
	virtual void PostNcDestroy() {}	// do NOT destroy this object
	DECLARE_DYNCREATE(ItemView);

	// Member variables
	OrbItem *client;
	int x, y;
	CRect bound;
	BOOL pinned;
	double activation, size, dsizedt;
	Spring sizeSpring;
	UINT sizeTimer;
	void SetSize(int dx, int dy);

	BOOL Pin(BOOL isPinned);	// pins/unpins the window
	virtual BOOL Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);

	//{{AFX_MSG(ItemView)
	afx_msg void OnPaint();
	afx_msg void OnMouseMove(UINT nFlags, CPoint point);
	afx_msg void OnLButtonUp(UINT nFlags, CPoint point);
	afx_msg LONG OnUpdateSize(UINT nFlags, LONG lParam);
	
	afx_msg LONG OnInitFetch(UINT h, LONG lParam);
	afx_msg LONG OnHostName(UINT h, LONG lParam);
	afx_msg LONG OnCreated(UINT h, LONG lParam);
	afx_msg LONG OnConfigured(UINT h, LONG lParam);
	afx_msg LONG OnConnect(UINT h, LONG lParam);
	afx_msg LONG OnSend(UINT h, LONG lParam);
	afx_msg LONG OnSelectReceive(UINT h, LONG lParam);
	afx_msg LONG OnReceive(UINT h, LONG lParam);
	afx_msg void OnTimer(UINT nIDEvent);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};	// ItemView

// user interface messages
#define WM_UPDATESIZE (WM_USER+101)
#define WM_UPDATEPOS (WM_USER+102)
#define WM_ANNEAL (WM_USER+103)
// socket-based messages
#define WM_SOCKINITFETCH (WM_USER+111)
#define WM_SOCKHOSTNAME (WM_USER+112)
#define WM_SOCKCREATED (WM_USER+113)
#define WM_SOCKCONFIGURED (WM_USER+114)
#define WM_SOCKCONNECTED (WM_USER+115)
#define WM_SOCKWRITE (WM_USER+116)
#define WM_SOCKSELREAD (WM_USER+117)
#define WM_SOCKREAD (WM_USER+118)

#endif
