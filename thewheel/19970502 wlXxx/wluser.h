// wlUser.h  Copyright (C) 1997  DG Lane
//
// Declares the wlUser class, which stores its profiles in a ".whl" file.  A particular
// _person_ may have more than one ".whl" file, though.
//
// Basically, stores the start and stop times for sessions, as well as particular module-
// specific values and statistics.

#ifndef _wlUser_h_
#define _wlUser_h_
      
class wlUser {
	public:
		wlUser();
		wlUser( char *name );
	   ~wlUser();

		startSession();
		endSession();
		
		logMessage( char *string );
		
	public:
		CString name,
				password;
		CFile   sessionLog;
		CObList docList;
};

#endif
