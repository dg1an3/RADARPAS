/**  oSpacer.java  98/06/06
  * 
  *  This is the basic self-layout unit.
  * 
  *  @author Derek Graham Lane
  *  @version 1.0
  */

package theWheel;

import java.awt.*;

/**  Class to represent a panel of theWheel.oView objects.
  */
public class oSpacer 
	extends o {

		Component myComponent;

		public void setComponent ( oComponent comp ) {
			myComponent = comp;
		}	

		public void layout ( ) {
		}

		////////////////////////////////////////////////////////////////////////
		// Testing code

		/**  Usage: java oPanel
		  */
		public static void main ( String args[] ) {
		}
}

////////////////////////////////////////////////////////////////////////
// Nothing after here.

