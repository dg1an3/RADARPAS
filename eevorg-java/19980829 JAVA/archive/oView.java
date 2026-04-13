//	oNetwork.java
// 	Implements a network of linked objects
//
//	Copyright (C) 1998, Derek Graham Lane

package	theWheel.view;
import	theWheel.core.*;

import	java.util.List;

class oView extends oSpacer {

//	Member variables
	private o		my;

//	Constructors
	public		oView		( oFrame	parent, 
					   double	x, 
					   double	y, 
					   double	size  ) 	{ }

//	Viewer registration methods (static)
	private static List	registeredViewList;
	public static	registerViewer	( )		{ }
	public static oView createView	( o 	for  )	{ }

//	Main loop(s)
	public void	update		( Time 	t  )	{ }
	public static void	main		( String 	args[]  )	{
	}
}

// 	Nothing after here.

