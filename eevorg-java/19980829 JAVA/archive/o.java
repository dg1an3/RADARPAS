////////////////////////////////////////////////////////
//	o.java
// 	Implements the o class, which is a linked object
//
//	Copyright (C) 1998, Derek Graham Lane

package theWheel.core;

import java.util.*;

class o extends Object {

	////////////////////////////////////////////////////
	// constructors

	public o ( )  {	}

	public o ( String initLabel ) 
		{	setLabel( initLabel );	}


	////////////////////////////////////////////////////
	// tableOfLinks: contains the object's peers

	private Hashtable tableOfLinks = new Hashtable();

	public final oLink getLink ( o oTo )		
		{	return (oLink)tableOfLinks.get((Object)oTo); 	}

	public void	setLink ( o oTo, double weight )
		{	oLink newLink = new oLink( oTo, weight );
			tableOfLinks.put(oTo, newLink); 
		}

	////////////////////////////////////////////////////
	// myLabel: the objects moniker

	private String myLabel;

	public String getLabel ( ) 
		{	return myLabel;	}

	public void setLabel( String toLabel ) 
		{ 	myLabel = toLabel;	}


	////////////////////////////////////////////////////
	// update is called "as often as possible"

	public void	update ( )	{ 	}


	////////////////////////////////////////////////////
	// debugging routines

	public void dump() 
		{	Enumeration en = tableOfLinks.elements();
			while (en.hasMoreElements()) {
				oLink nextLink = (oLink)en.nextElement();
				nextLink.dump(); 
			}
		}  

	public static void main	( String args[] )	
		{	// create a set of objects, then link them together and unlink them while creating and
			// destroying the objects
			System.out.println( "Creating 2 o objects..." );
			o thisO = new o("thisO");
			System.out.println( thisO.getLabel() + " = " + thisO );
			o thatO = new o("thatO");
			System.out.println( thatO.getLabel() + " = " + thatO );
			thisO.setLink( thatO, 0.5 );
			System.out.println( "thisO->thatO wgt = " + 
						thisO.getLink(thatO).getWeight() );
			thatO.setLink( thisO, 0.75 );
			System.out.println( "thatO->thisO wgt = " +
							thatO.getLink(thisO).getWeight() );

			o theOthero = new o("theOthero");
			theOthero.setLink( thisO, 0.45 );
			thisO.setLink( theOthero, 0.35 );
			theOthero.setLink( thatO, 0.65 );
			thatO.setLink( theOthero, 0.75 );

			System.out.println( "=====================================" );
			System.out.println( "thisO = " + thisO );
			thisO.dump();
			System.out.println( );
			System.out.println( "thatO = " + thisO );
			thatO.dump();
			System.out.println( );
			System.out.println( "theOthero = " + theOthero );
			theOthero.dump();
		}
}

////////////////////////////////////////////////////////
// 	Nothing after here.


