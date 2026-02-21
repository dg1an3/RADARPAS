//	oMapView.java
// 	Implements a view class
//	
//	Copyright (C) 1998, Derek Graham Lane

package	theWheel.view;
import	theWheel.core.*;

import	java.awt.*;

class oMapView extends oView	{

    oNetwork	myChildren;
    
    public	oMapView	( oNetwork newNetwork ) 
				    { oView((o)newNetwork);	}

    public void	add		( oSpacer another )	
				    { oList.add( another ) );	}

    public void	update		( ) { oList.update( next );
				      currChild++;		}
				      
    public static void	main	( String args[] ) {
    }
}

// 	Nothing after here.
