
wlUser::beginSession() {

	sessionLog << "theWheel " 
	sessionLog << theWheel::majorVersion << "." << theWheel::minorVersion << endl;
	sessionLog << "Copyright (C) 1997  DG Lane" << endl;

	sessionLog << "Beginning session for " << whose << "." << endl;
	
	startTime = ::GetCurrentTime();	
	sessionLog << "Start time: " << startTime << endl;
}

wlUser::endSession() {

	sessionLog << "theWheel terminating...";
	sessionLog << "done at " << ::GetCurrentTime << endl;
}