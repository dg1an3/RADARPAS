// OrbVwItm.cpp  Copyright (C) 1996 DG Lane

#include "stdafx.h"
#include "Orbis.h"
#include "OrbView.h"
#include "OrbVwItm.h"
#include "TextItem.h"

#include <math.h>

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

// OrbViewItem

IMPLEMENT_DYNAMIC(OrbViewItem, CWnd)

OrbViewItem::OrbViewItem(OrbView *parent, OrbItem *forItem, 
				int initx, int inity, int initActiv) { 
	item = forItem;
	activation = initActiv;
	x = initx;
	y = inity;
    	bound = CRect(x - activation/4, y - activation/4,
    				  x + activation/4, y + activation/4);
    	Create(NULL, "Dummy Name",	 // class and window names
    		WS_BORDER | WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE,	// styles
    		bound, parent, 1);	// rectangle, parent, child window ID
}	// OrbViewItem::OrbViewItem

OrbViewItem::~OrbViewItem() { }

void OrbViewItem::Move(int dx, int dy) {
	GetWindowRect(&bound);
	GetParent()->ScreenToClient(&bound);
	bound.OffsetRect(dx, dy);
	SetWindowPos(&wndTop,
		bound.left, bound.top,
		bound.right - bound.left, 
		bound.bottom - bound.top,
		SWP_NOZORDER);
	x += dx;
	y += dy;
}      // OrbViewItem::Move

void OrbViewItem::Inflate(int dx, int dy) {
	GetWindowRect(&bound);
	GetParent()->ScreenToClient(&bound);
	bound.InflateRect(dx, dy);
	SetWindowPos(&wndTop,
		bound.left, bound.top,
		bound.right - bound.left, 
		bound.bottom - bound.top,
		SWP_NOZORDER);
}	// OrbViewItem::Inflate

// #define PI 	(atan(1.0))
#define SINK_SIGMA 	200

double gauss(double x, double y, double s) { 
	return exp(-(x*x + y*y) / (s * s) ) /
			(sqrt(2 * PI) * s);
}	// gauss

double OrbViewItem::dEdx() {
	double dEdx = 0.0;
	double xi = (double)xpos();
	double yi = (double)ypos();
	double si =  (double)getSize();	
	OrbView *parent = (OrbView *)GetParent();
	for (POSITION pos = parent->iteml.GetHeadPosition(); pos != NULL;) {
		OrbViewItem *withItem = (OrbViewItem *)parent->iteml.GetNext(pos);
		if (withItem != this) {
			double xo = (double)withItem->xpos();
			double yo = (double)withItem->ypos();
			double so =  (double)withItem->getSize();	
			dEdx += -2 * (xi - xo) * gauss(xi - xo, yi - yo, so) / 
							  (so * so);
		}	// if
	}	// for
	dEdx -=  gauss(xi - 400, yi - 250, SINK_SIGMA) * (-2 * (xi - 400)) /
							      ((double)SINK_SIGMA * SINK_SIGMA);
	return dEdx;
}	// OrbViewItem::dEdx

double OrbViewItem::dEdy() {
	double dEdy = 0.0;
	double xi = (double)xpos();
	double yi = (double)ypos();
	double si =  (double)getSize();
	OrbView *parent = (OrbView *)GetParent();
	for (POSITION pos = parent->iteml.GetHeadPosition(); pos != NULL;) {
		OrbViewItem *withItem = (OrbViewItem *)parent->iteml.GetNext(pos);
		if (withItem != this) {
			double xo = (double)withItem->xpos();
			double yo = (double)withItem->ypos();
			double so =  (double)withItem->getSize();	
			dEdy += -2 * (yi - yo) * gauss(xi - xo, yi - yo, so) / 
							   (so * so);
		}	// if
	}	// for
	dEdy -= gauss(xi - 400, yi - 250, SINK_SIGMA) * (-2 * (yi - 250)) /
							     ((double)SINK_SIGMA * SINK_SIGMA);
	return dEdy;
}	// OrbViewItem::dEdy

double OrbViewItem::dEds() {
	double dEds = 0.0;
	double xi = (double)xpos();
	double yi = (double)ypos();
	double si =  (double)getSize();	
	OrbView *parent = (OrbView *)GetParent();
	for (POSITION pos = parent->iteml.GetHeadPosition(); pos != NULL;) {
		OrbViewItem *withItem = (OrbViewItem *)parent->iteml.GetNext(pos);
		if (withItem != this) {
			double xo = (double)withItem->xpos();
			double yo = (double)withItem->ypos();
			dEds += gauss(xo - xi, yo - yi, si) * ( 1 + ((xo - xi) * (xo - xi) + (yo - yi) * (yo - yi)) / 
													            (si * si) );
		}	// if
	}	// for
	dEds += (double)activation - 2.0*si;
	return dEds;
}	// OrbViewItem::dEds

int OrbViewItem::UpdateSizePos() {
	double dx = dEdx() * 1e+5;
	double dy = dEdy() * 1e+5;
	double ds = dEds();
	TRACE("dx = %10.10f  dy = %10.10f  ds = %10.10f\n", dx, dy, ds);
	if (dEds() > 0.0)
		Inflate(1, 1);
	else if (dEds() < 0.0)
		Inflate(-1, -1);
	if (fabs(dx) > 1.0)
		Move((int)-dx, 0);
	else if (rand() < abs((int)(dx*RAND_MAX)))
		Move((dx > 0.0) ? -1 : 1, 0);
	if (fabs(dy) > 1.0)
		Move(0, (int)-dy);
	else if (rand() < abs((int)(dx*RAND_MAX)))
		Move(0, (dy > 0.0) ? -1 : 1);
	// Move( (dx > 0.0) ? -1 : 1, (dy > 0.0) ? -1 : 1);
	// char *s = ((TextItem *)item)->title.GetBuffer(40);
	// TRACE("Item %s activation = %i  size = %i\n", s, activation, getSize());
	return 0;
	// returns items energy
}	// OrbViewItem::UpdateSizePos

BEGIN_MESSAGE_MAP(OrbViewItem, CWnd)
	//{{AFX_MSG_MAP(OrbViewItem)
	ON_WM_PAINT()
	ON_WM_MOUSEMOVE()
	ON_MESSAGE(WM_SOCKREAD, OnReceive);
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

// OrbViewItem message handlers

void OrbViewItem::OnPaint() {
	CPaintDC dc(this); // device context for painting
	CRect clientRect;
	GetClientRect(&clientRect);
	item->Draw(&dc, &clientRect);
	// Do not call CWnd::OnPaint() for painting messages
}	// OrbViewItem::OnPaint

void OrbViewItem::OnMouseMove(UINT nFlags, CPoint point) {
	// deltaActivation(1);
	activation++;
	UpdateSizePos();
	UpdateWindow();
	// ((OrbView *)GetParent())->OnUpdate(NULL, NULL, NULL);
}	// OrbViewItem::OnMouseMove

LONG OrbViewItem::OnHostName(HANDLE h, LONG lParam) {
	ASSERT(h == client->h);
	// TODO: interpret any errors
	struct sockaddr_in SockAddr;
	memset((char *)&SockAddr, 0, sizeof(SockAddr));  // initialize socket address structure
	SockAddr.sin_family = AF_INET;
	// TODO: handle explicit host address SockAddr.sin_addr.s_addr = inet_addr(host)
	struct hostent *hostEntry = client->hostData;
	memcpy((char *)&SockAddr.sin_addr, hostEntry->h_addr, hostEntry->h_length);
	delete [] hostData;
	// now initiate the connection
	SockAddr.sin_port = 80;	// TODO: handle other services
	u_short nProtocol = 6;	// TODO: handle other protocols
	if ((s = socket(AF_INET, SOCK_STREAM, nProtocol))  == INVALID_SOCKET)
		return
	// TODO: How to set socket to non-blocking mode?
	connect(s, (struct sockaddr *)&SockAddr, sizeof(SockAddr));
	client->h = WSAAsyncSelect(s, smt.GetSafeHwnd(), WM_SOCKCONNECT, FD_CONNECT);
}	// OrbViewItem::OnHostName

LONG OrbViewItem::OnConnect(HANDLE h, LONG lParam) 
	ASSERT(h == client->h);
	// TODO: interpret any errors
	// TODO: send any awaiting data
	client->h = WSAAsyncSelect(s, this->GetSafeHwnd(), SM_WRITE, FD_WRITE));
}	// OrbViewItem::OnConnect

LONG OrbViewItem::OnSend(HANDLE h, LONG lParam) {
	ASSERT(h == client->h);
	// TODO: interpret any errors
	CString getCommand;
	sprintf(getCommand->GetBuffer(100), 
		"GET %s\r\n"
		"User-agent: Orbis 1.0\r\n\r\n",
		client->url);
	result = send(s, getCommand, strlen(getCommand));
	ASSERT(result == strlen(getCommand));
	client->h = WSAAsyncSelect(s, smt.GetSafeHwns(),		WM_SOCKREAD, FD_READ);
}	// OrbViewItem::OnSend

void OrbViewItem::OnReceive(HANDLE h, LONG lParam) {
	ASSERT(h == client->h);
	int currLength = client->data.GetLength();
	char *newData = client->data.GetBuffer(currLength+2000);
	newData += currLength;
	recv(s, newData, 2000);
	client->data.ReleaseBuffer();
	client->h = WSAAsyncSelect(s, this->GetSafeHwns(), WM_SOCKREAD, FD_READ);
}	// OrbViewItem::OnReceive
