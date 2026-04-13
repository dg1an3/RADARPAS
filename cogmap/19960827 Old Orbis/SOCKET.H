// Socket.h  Asynchronous, object-oriented wrapper for winsock.dll
// Copyright (C) 1996  DG Lane

#ifndef __SOCKET_H__
#define __SOCKET_H__
	
extern "C" {
#include "winsock.h"
}

#define WM_SOCKHOSTNAME		(WM_USER+100)
#define WM_SOCKCONNECT		(WM_USER+101)
#define WM_SOCKREAD			(WM_USER+102)
#define WM_SOCKWRITE			(WM_USER+103)

class Socket {
public:
	Socket(OrbItem *forClient, char *host, char *fileName);
	~Socket();

	// Utilities
	void ParseURL(char *url, int *service, char *host, char *name);

	// Message handlers;
	void OnHostName();
	void OnConnect();
	void OnSend();
	void OnReceive();

	// Member variables
	OrbItem *client;
	CString host, name;
	struct sockaddr_in saSockAddr;
	char *hostData;
	SOCKET s;
	int error;
};	// Socket

#endif
