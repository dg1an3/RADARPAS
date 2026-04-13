//	oNetwork.java
// 	Implements a network of linked objects
//
//	Copyright (C) 1998, Derek Graham Lane

package	theWheel.core;

import	java.util.*;

class oNetwork extends o {

	private Vector nodes = new Vector();

	public oNetwork	( )		{ }
	
	public o add ( o another )	
				{ nodes.addElement( another );
				  return another;		}

	public final Vector getList ( )
				{ return nodes; 		}

	public void dump() { Enumeration en = nodes.elements();
				   while (en.hasElements()) {
					o nextNode = (o)en.nextElement();
					nextNode.dump; } }  

	public void	update		( )		{ }
	public static void	main		( String args[] )	{
		// create a set of objects, then link and unlink while creating and destroying the objects
		//	and calling update
		oNetwork thisNetwork = new oNetwork() { }
		System.out.println( "Created an object: " + thisNetwork );

		o dogNode = thisNetwork.add( new o("dog") );
		o catNode = thisNetwork.add( new o("cat") );
		dogNode.setLink( catNode, 0.25 );
		catNode.setLink( dogNode, 0.75 );

		o mouseNode = thisNetwork.add( new o("mouse") );
		mouseNode.setLink( dogNode, 0.15 );
		dogNode.setLink( mouseNode, 0.25 );
		mouseNode.setLink( catNode, 0.65 );
		catNode.setLink( mosueNode, 0.75 );

		thisNetwork.dump();		
	}
}

// 	Nothing after here.

