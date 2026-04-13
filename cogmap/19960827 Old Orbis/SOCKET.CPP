// Socket.cpp   Asynchronous/object-oriented wrapper for winsock.dll

#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "socket.h"

SM_HOSTNAME = 1;	// extra message for host name ID
SM_CONNECT;
SM_SEND;
SM_RECEIVE;

class SocketMsgTarget : public CWnd {
public:
	SocketMsgTarget();
	~SocketMsgTarget();
	
	Waiting(Socket *s, HANDLE h);	// indicates a socket is waiting
	OnSocketMsg();	// processes a message from a target
};	// class SocketMsgTarget

SocketMsgTarget::SocketMsgTarget() : CWnd::CWnd() {
	// Note that this initialization is meant to be called only once per application
	WORD version = (1 << 8) + 1;	// Winsock 1.1 or higher needed
	WSADATA winsockData;
	WSAStartup(version, &winsockData);
}	// SocketMsgTarget::SocketMsgTarget

SocketMsgTarget::~SocketMsgTarget() {
	WSACleanup();
}	// SocketMsgTarget::~SocketMsgTarget

SocketMsgTarget::Waiting(Socket *s, HANDLE h) {
}	

SocketMsgTarget::OnSocketMsg(uInt msg) {
	// find socket by handle
	switch (msg) {
		SM_HOSTNAME  : 
			s->OnHostName(error); 
			break;
		SM_CONNECT  :
			s->OnConnect(error);
			break;
		SM_READ  :
			s->OnReceive(error);
			break;
		SM_WRITE  :
			s->OnSend(error);
			break;
		default  :
			TRACE("Unknown msg to smt\n");
	}	// switch
}	// SocketMsgTarget::OnSocketMsg

SocketMsgTarget smt;

Socket::Socket(OrbItem *forClient, char *hostName, char *fileName) {
	client = forClient;
	name = fileName;
	s = INVALID_SOCKET;
	memset((char *)&saSockAddr, 0, sizeof(saSockAddr));  // initialize socket address structure
	saSockAddr.sin_family = AF_INET;
	// TODO: handle explicit host address
	// if ((saSockAddr.sin_addr.s_addr = inet_addr(host)) == INADDR_NONE)
	//        return;
	data = new char[MAXGETHOSTSTRUCT];
	smt.Waiting(this, WSAAsyncGetHostByName(smt.GetSafeHwnd(), 
		FD_HOSTNAME, host, data, MAXGETHOSTSTRUCT));
}	// Socket::Socket

Socket::~Socket() {
	closesocket(s);
}	// Socket::~Socket

void Socket::ParseURL(char *url, int *service, char *host, char *name) {

void OrbItem::ParseURL(CString URL) {
	int at = URL.Find(":");
	CString servName = URL.Left(at);
	URL = URL.Mid(at+3);	// 3 skips over ???://???
	if (servName == "http") { 
		service = http;
		at = URL.Find("/");
		host = URL.Left(at);
		url = URL.Mid(at);
	} else if (servName == "file") {
		service = file;
		host = "";
		url = URL;
		// host = "";
	} else {
		TRACE("unknown	service request\n");
	}	// if
}	// OrbItem::ParseURL
	
}	// Socket::ParseURL

