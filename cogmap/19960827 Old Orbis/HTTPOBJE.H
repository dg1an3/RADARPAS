// HTTPObje.h

#ifndef __HTTPOBJE_H__
#define __HTTPOBJE_H__

#include "socket.h"

class HTTPObject {
public:
	HTTPObject();
	~HTTPObject();

	int Fetch(char *host, char *URL);
	void Update();

	enum {	init, connecting, rxing, timeout, complete }; // states

	int getState();
	long getActLength();
	CString *getData();

	// Member variables	
private:
	int state;
	Socket *s;
	CString data;
	long actLength;
};	// HTTPObject

#endif
