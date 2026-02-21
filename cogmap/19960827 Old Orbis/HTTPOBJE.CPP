/* HTTPObje.cpp */

#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "httpobje.h"

HTTPObject::HTTPObject() {
	state = init;
	s = NULL;
	data = "";
	actLength = -1;
}	// HTTPObject::HTTPObject

HTTPObject::~HTTPObject() {
	delete s;
}	// HTTPObject::~HTTPObject

int HTTPObject::Fetch(char *host, char *URL) {
	s = new Socket(host, "http", "tcp");
	if (!s->IsValid())
		return -1;
	char *getCommand = new char[100];
	sprintf(getCommand, "GET %s\r\n"
		"Accept: text/plain, text/html\r\n"
		"User-Agent: qsock/1.0\r\n\r\n", URL);
	s->Send(getCommand, strlen(getCommand));
	delete getCommand;
	state = rxing;
	return 0;
}	// HTTPObject::HTTPObject

#define KEYW_LEN "Content-Length: "

BOOL ParseHeader(CString data, long *actLength) {	
	// decimates data as it parses
	// returns TRUE at end of header
	// parse the header to see if it contains the actual length
	int CRLF;
	while ((CRLF = data.Find("\r\n")) != 0) {
		TRACE("RESP> %s\n", data.Left(CRLF));
		if (data.Left(strlen(KEYW_LEN)) == KEYW_LEN) {
			*actLength = atol(data.Mid(strlen(KEYW_LEN)+1, 8));
		}	// if
		data = data.Mid(CRLF+2, data.GetLength());
		if (data.Left(1) == " ")	// remove blank space
			data = data.Mid(1, data.GetLength());
		if (data.Left(2) == "\r\n") {	// blank line -- terminates header
			data = data.Mid(2, data.GetLength());
			return TRUE;
		}	// if
	}	// while
	return FALSE;
}	// ParseHeader

void HTTPObject::Update() {
	if (state == rxing) {
		int result = 1;
		while ((s->ReceiveReady()) && (result != 0)) {
			char *buf = new char[1000];
			result = s->Receive(buf, 1000);
			data += buf;
			delete [] buf;
		}	// while
	}	// if
	/* switch (state) {
		case rxheader  :
			if (ParseHeader(data, &actLength))
				state = rxobject;
			data.ReleaseBuffer();
			break;
		case rxobject  :
			if ((actLength > 0) && (data.GetLength() >= actLength))
				state = complete;
			break;
	}	*/
}	// HTTPObject::Update 

int HTTPObject::getState() {
	Update();
	return state;
}	// HTTPObject::getState

long HTTPObject::getActLength() {
	Update();
	return actLength;
}	// HTTPObject::getActualLength

CString *HTTPObject::getData() {
	Update();
	return &data;
}	// getData;

