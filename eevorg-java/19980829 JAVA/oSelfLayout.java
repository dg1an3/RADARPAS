/**  oSelfLayout.java  98/06/06
  *  Copyright (C) 1998  Derek Graham Lane
  *
  *  This is the LayoutManager for the self-organizing map layout.
  *  The SOM layout is actually performed by the individual oSpacer
  *  elements interacting with each other
  *
  *  @see oSpacer
  * 
  *  @author Derek Graham Lane
  *  @version 1.0
  */

package theWheel;

import java.awt.*;
import java.util.*;

/**  Class representing the Self-Organizing Map Layout
  *
  *  @see LayoutManager2
  *  @see oSpacer
  */
public class oSelfLayout
	implements LayoutManager2 {
	
		////////////////////////////////////////////////////////////////////////
		// Component management

		/**  NOT IMPLEMENTED.
		  *  Use <CODE>addLayoutComponent(Component,Object)</CODE> instead.
		  *
		  *  @see LayoutManager
		  */
		public void addLayoutComponent ( String name,
                                             Component comp ) {
		}

		/**  Container to hold the oSpacer constraint objects.  
		  *  Use addLayoutComponent and removeLayoutComponent to add and
		  *  remove elements.  oSpacers are keyed on the oComponents that
		  *  they lay out.
		  *
		  *  @see addLayoutComponent
		  *  @see removeLayoutComponent
		  */
		Hashtable myConstraint = new Hashtable();

		/**  Adds the specified Component, using the specified constraint
              *  Object.  oSelfLayout was designed to accept oComponent-derived
		  *  components and oSpacer-derived constraints. 
		  *
		  *  @see LayoutManager2
		  *
		  *  @param comp        Component (oComponent) to add.
		  *  @param constraints Object (oSpacer) to use to constrain the
		  *                     Component.
		  */
		public void addLayoutComponent ( Component comp,
                                         	   Object constraint ) {
            /*                             	    
			if (!(comp instanceof oComponent) || 
	                !(constraint instanceof oSpacer))
				throw new IllegalArgumentException();
			((oSpacer)constraint).setComponent((oComponent)comp);
			*/
			if (constraint != null)
    			myConstraint.put(comp,constraint);
		}

		/**  Removes the specified Component from the layout, adjusting
		  *  everything as needed.
		  *
		  *  @see LayoutManager
		  *
		  *  @param comp        Component (oComponent) to add.
		  *  @param constraints Object (oSpacer) to use to constrain the
		  *                     Component.
		  */
		public void removeLayoutComponent ( Component comp ) {
			myConstraint.remove((Object)comp);
		}

		////////////////////////////////////////////////////////////////////////
		// Container sizing

		/**  Returns the preferred size of the container.
		  *
		  *  @see LayoutManager
		  *
		  *  @param parent      Container whose size to determine.
		  *  @return            The desired Dimension of the Container.
		  */
		public Dimension preferredLayoutSize ( Container parent ) {
			return new Dimension(256,256);
		}

		/**  Returns the minimum size of the container.
		  *
		  *  @see LayoutManager
		  *
		  *  @param parent      Container whose size to determine.
		  *  @return            The minimum Dimension of the Container.
		  */
		public Dimension minimumLayoutSize ( Container parent ) {
			return new Dimension(256,256);
		} 

		/**  Returns the maximum size of the container.
		  *
		  *  @see LayoutManager2
		  *
		  *  @param parent      Container whose size to determine.
		  *  @return            The maximum Dimension of the Container.
		  */
		public Dimension maximumLayoutSize ( Container parent ) {
			return new Dimension(256,256);
		}
	
		////////////////////////////////////////////////////////////////////////
		// Container placement

		/**  Returns the alignment of the container along the X-axis, with 0
              *  indicating the left-most alignment, and 1 indicating the right-most
              *  alignment.
		  *
		  *  @see LayoutManager2
		  *
		  *  @param target      Container whose alignment to determine.
		  *  @return            The alignment along the X-axis, from 0 to 1.
		  */
		public float getLayoutAlignmentX ( Container target ) {
			return 0.0f;
		}

		/**  Returns the alignment of the container along the Y-axis, with 0
              *  indicating the top-most alignment, and 1 indicating the bottom-most
              *  alignment.
		  *
		  *  @see LayoutManager2
		  *
		  *  @param target      Container whose alignment to determine.
		  *  @return            The alignment along the Y-axis, from 0 to 1.
		  */
		public float getLayoutAlignmentY ( Container target ) {
			return 0.0f;
		}

		////////////////////////////////////////////////////////////////////////
		// Container layout

		/**  Performs the layout.  The initial implementation is to iteratively
		  *  call the oSpacer elements, allowing each to lay itself out based on 
		  *  the interaction fields of its neighbors, until a convergence 
              *  criterion is met.
		  *
		  *  Later implementations will use a thread to do the layout, and this
		  *  call will either boost the priority of the thread, or will resume
		  *  the suspended thread.
		  *
		  *  @see LayoutManager
		  *
		  *  @param target      Container to layout
		  */
		public void layoutContainer ( Container target ) {
			Enumeration en = myConstraint.elements();
			while (en.hasMoreElements()) {
				oSpacer constraint = (oSpacer)en.nextElement();
				constraint.layout();
			}
		}

		/**  Invalidates the layout, clearing any cached information.
		  *  This call may be used to induce a new round of iterative layout.
		  *
		  *  @see LayoutManager2
		  *
		  *  @param target	Container to invalidate
		  */
		public void invalidateLayout ( Container target ) {
		}

		////////////////////////////////////////////////////////////////////////
		// Testing code

		/**  Usage: java oSelfLayout
		  */
		public static void main ( String args[] ) {
		    Frame testFrame = new Frame("oSelfLayout Test");
		    testFrame.setLayout(new oSelfLayout());
    		testFrame.setSize(430,270);
    		testFrame.addWindowListener(new WindowCloser());
    		
		    symantec.itools.awt.ImageButton imageButton1 = 
		        new symantec.itools.awt.ImageButton();
    		imageButton1.setBounds(108,84,96,40);
    		testFrame.add(imageButton1);
    		
		    symantec.itools.awt.ImageButton imageButton2 = 
		        new symantec.itools.awt.ImageButton();
    		imageButton2.setBounds(228,84,96,40);
    		testFrame.add(imageButton2);
    		
		    symantec.itools.awt.ImageButton imageButton3 = 
		        new symantec.itools.awt.ImageButton();
    		imageButton3.setBounds(168,144,96,40);
    		testFrame.add(imageButton3);
    		
    		testFrame.show();
		}
}

////////////////////////////////////////////////////////////////////////
// Nothing after here.

