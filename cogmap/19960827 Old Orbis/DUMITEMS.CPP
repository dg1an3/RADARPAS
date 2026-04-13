    WordItem *tempItem;
    AddItem(tempItem = new WordItem("desk"));
    tempItem->corr = new REAL[6];
    tempItem->corr[1] = 1.0;
    tempItem->corr[2] = 0.4; 
	tempItem->corr[3] = 0.5; 
	tempItem->corr[4] = 0.7;
	tempItem->corr[5] = 0.8;
	
    AddItem(tempItem = new WordItem("chair"));
    tempItem->corr = new REAL[6];
    tempItem->corr[0] = 1.0;
	tempItem->corr[2] = 0.3; 
	tempItem->corr[3] = 0.5; 
	tempItem->corr[4] = 1.0; 
	tempItem->corr[5] = 0.5; 

	AddItem(tempItem = new WordItem("refrigerator"));
    tempItem->corr = new REAL[6];
    tempItem->corr[0] = 0.4;
    tempItem->corr[1] = 0.3;
	tempItem->corr[3] = 0.4; 
	tempItem->corr[4] = 0.3; 
	tempItem->corr[5] = 0.9; 

	AddItem(tempItem = new WordItem("piano"));
    tempItem->corr = new REAL[6];
    tempItem->corr[0] = 0.5;
    tempItem->corr[1] = 0.5;
    tempItem->corr[2] = 0.4;
	tempItem->corr[4] = 0.3; 
	tempItem->corr[5] = 0.4;
	
	AddItem(tempItem = new WordItem("futon"));
    tempItem->corr = new REAL[6];
    tempItem->corr[0] = 0.7;
    tempItem->corr[1] = 1.0;
    tempItem->corr[2] = 0.3;
    tempItem->corr[3] = 0.3;
	tempItem->corr[5] = 0.3;

	AddItem(tempItem = new WordItem("armoir"));
    tempItem->corr = new REAL[6];	
    tempItem->corr[0] = 0.8; 
    tempItem->corr[1] = 0.5; 
    tempItem->corr[2] = 0.9; 
    tempItem->corr[3] = 0.4;
	tempItem->corr[4] = 0.3;
