// OrbVwItm.h  Copyright (C) 1996  DG Lane

#ifndef __ORBVWITM_H__
#define __ORBVWITM_H__

#include "OrbFrame.h"

class OrbViewItem : public CWnd {
public:
	// OrbViewItem() { };
	OrbViewItem(OrbFrame *parent, OrbItem *forItem, 
				int initx, int inity, int initActiv);
	virtual ~OrbViewItem();	
	DECLARE_DYNAMIC(OrbViewItem);

	int xpos() { return x; }
	int ypos() { return y; }
	void Move(int dx, int dy);
	
	int getSize() { return bound.right - bound.left; }
	void Inflate(int dx, int dy);

	int UpdateSizePos();	// returns items energy
	double dEdx();	// helpers for UpdateSizePos
	double dEdy();
	double dEds();

	//{{AFX_MSG(OrbViewItem)
	afx_msg void OnPaint();
	afx_msg void OnMouseMove(UINT nFlags, CPoint point);
	afx_msg LONG OnHostName(HANDLE h, LONG lParam);
	afx_msg LONG OnConnect(HANDLE h, LONG lParam);
	afx_msg LONG OnSend(HANDLE h, LONG lParam);
	afx_msg LONG OnReceive(HANDLE h, LONG lParam);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()

	// Member variables
	OrbItem *client;
	int activation;
	int x, y;
	CRect bound;
};	// OrbViewItem

// socket-based messages
#define WM_SOCKHOSTNAME		(WM_USER+100)
#define WM_SOCKCONNECT		(WM_USER+101)
#define WM_SOCKREAD			(WM_USER+102)
#define WM_SOCKWRITE			(WM_USER+103)

#endif
