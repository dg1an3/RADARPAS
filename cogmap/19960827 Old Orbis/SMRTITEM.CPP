	WordItem *tempItem;
	AddItem(tempItem = new WordItem("Time"));
	tempItem->corr = new REAL[7];
	tempItem->corr[0] = 1.0;	// Time
	tempItem->corr[1] = 0.8;	// Events
	tempItem->corr[2] = 0.3; 	// Space
	tempItem->corr[3] = 0.3; 	// Earth
	tempItem->corr[4] = 0.3;	// Objects
	tempItem->corr[5] = 0.3;	// People
	tempItem->corr[6] = 0.6;	// Knowledge

	AddItem(tempItem = new WordItem("Events"));
	tempItem->corr = new REAL[7];
	tempItem->corr[0] = 0.8;	// Time
	tempItem->corr[1] = 1.0;	// Events
	tempItem->corr[2] = 0.7; 	// Space
	tempItem->corr[3] = 0.7; 	// Earth
	tempItem->corr[4] = 0.2;	// Objects
	tempItem->corr[5] = 0.6;	// People
	tempItem->corr[6] = 0.6;	// Knowledge
	
	AddItem(tempItem = new WordItem("Space"));
	tempItem->corr = new REAL[7];
	tempItem->corr[0] = 0.5;	// Time
	tempItem->corr[1] = 0.7;	// Events
	tempItem->corr[2] = 1.0; 	// Space
	tempItem->corr[3] = 0.7; 	// Earth
	tempItem->corr[4] = 0.6;	// Objects
	tempItem->corr[5] = 0.6;	// People
	tempItem->corr[6] = 0.6;	// Knowledge

	AddItem(tempItem = new WordItem("Earth"));
	tempItem->corr = new REAL[7];
	tempItem->corr[0] = 0.3;	// Time
	tempItem->corr[1] = 0.6;	// Events
	tempItem->corr[2] = 0.7; 	// Space
	tempItem->corr[3] = 1.0; 	// Earth
	tempItem->corr[4] = 0.7;	// Objects
	tempItem->corr[5] = 0.7;	// People
	tempItem->corr[6] = 0.6;	// Knowledge

	AddItem(tempItem = new WordItem("Objects"));
	tempItem->corr = new REAL[7];
	tempItem->corr[0] = 0.3;	// Time
	tempItem->corr[1] = 0.3;	// Events
	tempItem->corr[2] = 0.6; 	// Space
	tempItem->corr[3] = 0.6; 	// Earth
	tempItem->corr[4] = 1.0;	// Objects
	tempItem->corr[5] = 0.8;	// People
	tempItem->corr[6] = 0.7;	// Knowledge

	AddItem(tempItem = new WordItem("People"));
	tempItem->corr = new REAL[7];
	tempItem->corr[0] = 0.4;	// Time
	tempItem->corr[1] = 0.6;	// Events
	tempItem->corr[2] = 0.3; 	// Space
	tempItem->corr[3] = 0.7; 	// Earth
	tempItem->corr[4] = 0.8;	// Objects
	tempItem->corr[5] = 1.0;	// People
	tempItem->corr[6] = 0.8;	// Knowledge

	AddItem(tempItem = new WordItem("Knowledge"));
	tempItem->corr = new REAL[7];
	tempItem->corr[0] = 0.6;	// Time
	tempItem->corr[1] = 0.6;	// Events
	tempItem->corr[2] = 0.6; 	// Space
	tempItem->corr[3] = 0.6; 	// Earth
	tempItem->corr[4] = 0.7;	// Objects
	tempItem->corr[5] = 0.8;	// People
	tempItem->corr[6] = 1.0;	// Knowledge
	
