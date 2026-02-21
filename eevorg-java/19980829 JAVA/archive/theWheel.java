//  theWheel.java
//  Encapsulates theWheel application object
//
//  Copyright (C) 1998  Derek Graham Lane

// package theWheel.view;
// import theWheel.core.*;
import java.awt.*;

public class theWheel extends Frame {

    oMapView myMap;
    oNetwork myNetwork;
    
    // 
    //	constructor.
    public theWheel () {
	initMenu();
    }

    private Menu addMenu(MenuBar currMenuBar, String label) {
    
	Menu newMenu = new Menu( label );
	currMenuBar.add( newMenu );
	return newMenu;
    }
    
    private MenuItem addMenuItem( Menu currMenu, 
	    String label, ActionListener doWhen ) {
	    
	MenuItem newItem = new MenuItem( label );
	newItem.addListener( doWhen );
	currMenu.add( newItem );
    }
    
    MenuBar	myMenuBar;
    private void initMenu( ) {
	myMenuBar = new MenuBar();
	
	Menu cm;
	cm = addMenu( myMenuBar, "File" );
	addMenuItem( cm, "Open...", new ActionListener(this) );
	addMenuItem( cm, "Save...", new ActionListener(this) );
	addMenuSeparator( cm );
	addMenuItem( cm, "Quit",    new ActionListener(this) );
	
	cm = addMenu( myMenuBar, "Help" );
	addMenuItem( cm, "Help...", new ActionListener(this) );
	addMenuItem( cm, "About...", new ActionListener(this) );
    }
    
    //
    //	serialization.
    void    onFileNew() {
    }
    void    onFileOpen() {
    }
    void    onFileSave() {
    }
    
    void    onQuit() {
    }
    
    void    onInsertObject( o oNew ) {
    }
    
    //	
    //	the application's main.
    public static void main(String args[]) {
    
	Frame theFrame = new theWheel();
	theFrame.setSize( 300, 150 );
	theFrame.show();
	
	if (args.length > 0)
	    theFrame.onFileOpen( args[0] );
    }
}

//
//  Nothing after here.
