// ItemView.cpp  Copyright (C) 1996 DG Lane

#include "stdafx.h"
// #include "Orbis.h"
#include "OrbFrame.h"
#include "ItemView.h"
// #include "TextItem.h"

#include <math.h>

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

IMPLEMENT_DYNCREATE(ItemView, CMDIChildWnd)

ItemView::ItemView() { 
	client = NULL;
	activation = 4;
	dsizedt = 0.0;
	x = (int)((long)rand()*500/RAND_MAX) + (int)activation/2;
	y = (int)((long)rand()*300/RAND_MAX) + (int)activation/2;
    	bound = CRect(x - (int)activation/4, y - (int)activation/4,
    				  x + (int)activation/4, y + (int)activation/4);
    	ASSERT(AfxGetApp()->m_pMainWnd != NULL);
    	Create(NULL, "Dummy Name",	 // class and window names
    		WS_BORDER | WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE,	// styles
    		// WS_CAPTION | WS_VSCROLL | WS_CHILD | WS_VISIBLE,
    		bound);	// rectangle, parent, child window ID
    	Inflate(1,1);
    	activation = 10000;    // = size;
    	pinned = FALSE;
    	PostMessage(WM_UPDATESIZE);
}	// ItemView::ItemView

ItemView::~ItemView() { }

void ItemView::SetSize(int x, int y) {
	GetWindowRect(&bound);
	GetParent()->ScreenToClient(&bound);
	bound.InflateRect(x - (bound.right - bound.left), 
		y - (bound.bottom - bound.top));
	SetWindowPos(&wndTop,
		bound.left, bound.top,
		bound.right - bound.left, 
		bound.bottom - bound.top,
		SWP_NOZORDER);
	size = (bound.right - bound.left)*(bound.bottom - bound.top);
}	// ItemView::SetSize

BOOL ItemView::Pin(BOOL isPinned) {
	pinned = isPinned;
	if (pinned) {	// pin
		ASSERT(DestroyWindow());
		ASSERT(this != NULL);
		activation = 400;
	    	bound = CRect(x - (int)activation/4, y - (int)activation/4,
	    				  x + (int)activation/4, y + (int)activation/4);
	    	ASSERT(AfxGetApp()->m_pMainWnd != NULL);
	    	ASSERT(client != NULL);
	    	Create(NULL, client->url,	 // class and window names
	    		WS_CAPTION | WS_MAXIMIZEBOX | WS_MINIMIZEBOX | WS_VSCROLL | 
	    		WS_CHILD | WS_VISIBLE, bound);
	} else {	// unpin
		ASSERT(DestroyWindow());
		activation = 300;
	    	bound = CRect(x - (int)activation/4, y - (int)activation/4,
	    				  x + (int)activation/4, y + (int)activation/4);
	    	ASSERT(AfxGetApp()->m_pMainWnd != NULL);
	    	Create(NULL, client->url,	 // class and window names
	    		WS_BORDER | WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE,	// styles
	    		bound);	// rectangle, parent, child window ID
	}	// if
	return pinned;
}	// ItemView::Pin

BEGIN_MESSAGE_MAP(ItemView, CWnd)
	//{{AFX_MSG_MAP(ItemView)
	ON_WM_PAINT()
	ON_WM_MOUSEMOVE()
	ON_WM_LBUTTONUP()
	ON_MESSAGE(WM_UPDATESIZE, OnUpdateSize)
	ON_MESSAGE(WM_SOCKINITFETCH, OnInitFetch)
	ON_MESSAGE(WM_SOCKHOSTNAME, OnHostName)
	ON_MESSAGE(WM_SOCKCREATED, OnCreated)
	ON_MESSAGE(WM_SOCKCONFIGURED, OnConfigured)
	ON_MESSAGE(WM_SOCKCONNECTED, OnConnect)
	ON_MESSAGE(WM_SOCKWRITE, OnSend)
	ON_MESSAGE(WM_SOCKSELREAD, OnSelectReceive)
	ON_MESSAGE(WM_SOCKREAD, OnReceive)
	ON_WM_TIMER()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

// User-interface messages

BOOL ItemView::Draw(CDC* pDC, LPCRECT lpBounds, LPCRECT lpWBound, CDC *pFormatDC) {
	return TRUE;
}	// ItemView::Draw

void ItemView::OnPaint() {
	CPaintDC dc(this); // device context for painting
	CRect clientRect;
	GetClientRect(&clientRect);
	if (client != NULL)
		client->Draw(&dc, &clientRect);
	else
		TRACE("Painting a NULL client\n");
	// Do not call CWnd::OnPaint() for painting messages
}	// ItemView::OnPaint

#define DACTDMICKEY 400

void ItemView::OnMouseMove(UINT nFlags, CPoint point) {
	activation += DACTDMICKEY;
	// TODO: Check if currMsg->time > sizeSpring->t0;
	sizeSpring->Setxf(GetCurrentMessage()->time, activation);
	// TODO: increase activation of linked objects
	PostMessage(WM_UPDATESIZE);
	UpdateWindow();
	// ((OrbFrame *)GetParent())->OnUpdate(NULL, NULL, NULL);
}	// ItemView::OnMouseMove

#define SPRINGK 0.2 // 1/sec^2
#define FRICTIONK 0.10
#define FIXEDDSIZE 100.0	// pixels^2
#define THRESHOLD 0.01
#define SIZETIMER 7

LONG ItemView::OnUpdateSize(UINT wParam, LONG lParam) {
	// if ((activation - size) < THRESHOLD)
	//	return 0;
	double area, dareadt;
	sizeSpring->eval(GetCurrentMessage()->time, &area, &dareadt);
	// Inflate(delta, delta);
	int size = (int)sqrt(area);
	SetSize(size, size);
	KillTimer(sizeTimer);
	sizeTimer = SetTimer(SIZETIMER, (int)(1000.0 / 
					((dareadt != 0.0) ? dareadt : 0.01), NULL);
	ASSERT(sizeTimer != 0);
	return 0;
}	// ItemView::OnUpdateSize

void ItemView::OnTimer(UINT nIDEvent) {
	if (nIDEvent = SIZETIMER)
		PostMessage(WM_UPDATESIZE);
	else
		ASSERT(0);
	// CWnd::OnTimer(nIDEvent);
}	// ItemView::OnTimer

void ItemView::OnLButtonUp(UINT nFlags, CPoint point) {
	Pin(!pinned);
	// Invalidate();
	CWnd::OnLButtonUp(nFlags, point);
}	// ItemView::OnLButtonUp

// Socket messages

#define WSAGETASYNCERROR(lParam) HIWORD(lParam)
#define SOCKERROR(in, code) { TRACE("Socket error in %s, line = %i, " \
	"code = %i", in, __LINE__, code); \
	client->state = OrbItem::socketError; }

LONG ItemView::OnInitFetch(UINT h, LONG lParam) {	// retrieve host address
	client->hostData = new char[MAXGETHOSTSTRUCT]; 
		ASSERT(client->hostData != NULL);
	UINT errCode = (UINT)WSAAsyncGetHostByName(GetSafeHwnd(), 
		WM_SOCKHOSTNAME, client->host.GetBuffer(40), 
		client->hostData, MAXGETHOSTSTRUCT);
	if (errCode != 0)
		errCode = WSAGetLastError();
		if ((errCode == WSAEINPROGRESS) || (errCode == WSAEWOULDBLOCK))
			PostMessage(WM_SOCKINITFETCH);	// retry
		else
			SOCKERROR("OnInitFetch", errCode);
	return 0;
}	// ItemView::OnInitFetch

LONG ItemView::OnHostName(UINT h, LONG lParam) {	// create socket
	UINT errCode = WSAGETASYNCERROR(lParam);
	if (errCode == 0) {	// no errors
		memset((char *)&client->SockAddr, 0, sizeof(client->SockAddr));
		client->SockAddr.sin_family = AF_INET;
		// TODO: handle explicit host address SockAddr.sin_addr.s_addr = inet_addr(host)
		struct hostent *hostEntry = (struct hostent *)(client->hostData); 
			ASSERT(client->hostData != NULL);
		memcpy((char *)&client->SockAddr.sin_addr, hostEntry->h_addr, hostEntry->h_length);
		client->SockAddr.sin_port = htons(80);	// TODO: handle other services
		u_short nProtocol = 6;	// TODO: handle other protocols
		client->s = socket(AF_INET, SOCK_STREAM, nProtocol);
		if (client->s != INVALID_SOCKET) {
			PostMessage(WM_SOCKCREATED);
			delete [] client->hostData;
		} else {
			errCode = WSAGetLastError();
			if ((errCode == WSAEINPROGRESS) ||
					(errCode == WSAEMFILE) ||
					(errCode == WSAENOBUFS))	// try again
				PostMessage(WM_SOCKHOSTNAME, h, 0);
			else
				SOCKERROR("OnHostName", errCode);
		}	// if
	} else if (errCode == WSATRY_AGAIN)
		PostMessage(WM_SOCKINITFETCH);
	else if (errCode == WSAHOST_NOT_FOUND)
		client->state = OrbItem::badURL;
	else
		SOCKERROR("OnHostName", errCode);
	client->data = "Connecting to ";
	client->data += client->host;
	Invalidate();
	return 0;
}	// ItemView::OnHostName

LONG ItemView::OnCreated(UINT h, LONG lParam) {		// configure the socket
	UINT errCode = ioctlsocket(client->s, FIONBIO, NULL);   // set to non-blocking mode
	if (errCode == 0)
		PostMessage(WM_SOCKCONFIGURED);
	else {
		errCode = WSAGetLastError();
		if ((errCode == WSAEINPROGRESS) || (errCode == WSAEWOULDBLOCK))
			PostMessage(WM_SOCKCREATED);
		else
			SOCKERROR("OnCreated", errCode);
	}	// if
	return 0;
}	// ItemView::OnCreated

LONG ItemView::OnConfigured(UINT h, LONG lParam) {	// initiate the connection
	UINT errCode = connect(client->s, (struct sockaddr *)&client->SockAddr, 
		sizeof(client->SockAddr));
	if (errCode == 0)
		errCode = WSAAsyncSelect(client->s, GetSafeHwnd(), WM_SOCKCONNECTED, FD_CONNECT);
	if (errCode != 0) {
		errCode = WSAGetLastError();
		if (errCode == WSAEINPROGRESS)
			PostMessage(WM_SOCKCONFIGURED);
		else
			SOCKERROR("OnConfigured", errCode);
	}	// if
	return 0;
}	// ItemView::OnConfigured

LONG ItemView::OnConnect(UINT h, LONG lParam) { 
	ASSERT(LOWORD(lParam) == FD_CONNECT);
	UINT errCode = WSAGETASYNCERROR(lParam);
	if (errCode == 0)
		errCode = WSAAsyncSelect(client->s, GetSafeHwnd(), WM_SOCKWRITE, FD_WRITE);
	if (errCode != 0) {
	      errCode = WSAGetLastError();
		if (errCode == WSAEINPROGRESS)
			PostMessage(WM_SOCKCONNECTED, h, lParam);
		else
			SOCKERROR("OnConnect", errCode);
	}	// if
	client->data = "Retrieving ";
	client->data += client->host;	
	client->data += client->url;
	Invalidate();
	return 0;
}	// ItemView::OnConnect

LONG ItemView::OnSend(UINT h, LONG lParam) {
	ASSERT(LOWORD(lParam) == FD_WRITE);
	UINT errCode = WSAGETASYNCERROR(lParam);
	if (errCode == 0) {	
		CString getCommand;
		sprintf(getCommand.GetBuffer(100), 
			"GET %s\r\n"
			// "HEAD %s\r\n"
			"User-agent: Orbis 1.0\r\n\r\n",
			client->url);
		errCode = send(client->s, getCommand.GetBuffer(100), strlen(getCommand), 0);
		if (errCode == 0)
			PostMessage(WM_SOCKSELREAD);
		else {
	      	errCode = WSAGetLastError();
			if (errCode == WSAEINPROGRESS)
				PostMessage(WM_SOCKCONNECTED);
			else
				SOCKERROR("OnSend", errCode);
		}	// if
	} else
		SOCKERROR("OnSend", errCode);
	return 0;
}	// ItemView::OnSend

LONG ItemView::OnSelectReceive(UINT h, LONG lParam) {
	UINT errCode = WSAAsyncSelect(client->s, GetSafeHwnd(), WM_SOCKREAD, FD_READ);
	if (errCode != 0) {
	      errCode = WSAGetLastError();
		if (errCode == WSAEINPROGRESS)
			PostMessage(WM_SOCKSELREAD);
		else
			SOCKERROR("OnSelectReceive", errCode);
	}	// if
	return 0;
}	// ItemView::OnSelectReceive

LONG ItemView::OnReceive(UINT h, LONG lParam) {
	ASSERT(LOWORD(lParam) == FD_READ);
	UINT errCode = WSAGETASYNCERROR(lParam);
	if (errCode == 0) {
		// disable SM_SOCKREAD msg
		errCode = WSAAsyncSelect(client->s, GetSafeHwnd(), 0, 0);
		if (errCode == WSAEINPROGRESS)
			PostMessage(WM_SOCKSELREAD);
		else if (errCode == 0) {
			char *newData = new char[2000]; ASSERT(newData != NULL);
			errCode = recv(client->s, newData, 1999, 0);
			if (errCode != SOCKET_ERROR) {
				newData[errCode] = 0;
				client->data += newData;
				PostMessage(WM_SOCKSELREAD);
			} else {
				errCode = WSAGetLastError();
				if (errCode == WSAEINPROGRESS) {
					PostMessage(WM_SOCKSELREAD);
				} else
					SOCKERROR("OnReceive", errCode);
			}	// if
			delete [] newData;
		} else
			SOCKERROR("OnReceive", errCode);
	} else
		SOCKERROR("OnReceive", errCode);
	return 0;
}	// ItemView::OnReceive


