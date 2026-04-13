    WordItem *tempItem;
    AddItem(tempItem = new WordItem(this, "desk"));
    AddItem(tempItem = new WordItem(this, "chair"));
	AddItem(tempItem = new WordItem(this, "refrigerator"));
	AddItem(tempItem = new WordItem(this, "piano"));
	AddItem(tempItem = new WordItem(this, "futon"));
	AddItem(tempItem = new WordItem(this, "armoir"));
	recalcCorr();
	
    tempItem->corr[1] = 1.0;
    tempItem->corr[2] = 0.4; 
	tempItem->corr[3] = 0.5; 
	tempItem->corr[4] = 0.7;
	tempItem->corr[5] = 0.8;
	
    tempItem->corr[0] = 1.0;
	tempItem->corr[2] = 0.3; 
	tempItem->corr[3] = 0.5; 
	tempItem->corr[4] = 1.0; 
	tempItem->corr[5] = 0.5; 

    tempItem->corr[0] = 0.4;
    tempItem->corr[1] = 0.3;
	tempItem->corr[3] = 0.4; 
	tempItem->corr[4] = 0.3; 
	tempItem->corr[5] = 0.9; 

    tempItem->corr[0] = 0.5;
    tempItem->corr[1] = 0.5;
    tempItem->corr[2] = 0.4;
	tempItem->corr[4] = 0.3; 
	tempItem->corr[5] = 0.4;
	
    tempItem->corr[0] = 0.7;
    tempItem->corr[1] = 1.0;
    tempItem->corr[2] = 0.3;
    tempItem->corr[3] = 0.3;
	tempItem->corr[5] = 0.3;

    tempItem->corr[0] = 0.8; 
    tempItem->corr[1] = 0.5; 
    tempItem->corr[2] = 0.9; 
    tempItem->corr[3] = 0.4;
	tempItem->corr[4] = 0.3;
