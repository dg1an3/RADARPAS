/**  oPanel.java  98/06/06
  * 
  *  This is the main Panel base class for theWheel object networks.
  * 
  *  @author Derek Graham Lane
  *  @version 1.0
  */

package theWheel;

import java.awt.*;

/**  Class to represent a panel of theWheel.oView objects.
  */
public class oPanel 
	extends Panel {
	
		////////////////////////////////////////////////////////////////////////
		// Constructor

		/**  Default constructor
		  */
		public oPanel() {
		}

		////////////////////////////////////////////////////////////////////////
		// Testing code

		/**  Usage: java oPanel
		  */
		public static void main ( String args[] ) {

			oPanel thePanel = new oPanel();
			thePanel.setSize(450,250);
			thePanel.setLocation(0,50);
			thePanel.setLayout(null);
			
			Button newButton = new Button("Welcome to theWheel!");
			newButton.setSize(200,50);
			newButton.setLocation(50,50);
			thePanel.add(newButton);

			Button newButton2 = new Button("Point at me!!!");
			newButton2.setSize(200,50);
			newButton2.setLocation(50,150);
			thePanel.add(newButton2);
			
			Button newButton3 = new Button("Click on me!!!");
			newButton3.setSize(200,50);
			newButton3.setLocation(50,250);
			thePanel.add(newButton3);
			
			Button newButton4 = new Button("Click on me!!!");
			newButton4.setSize(200,50);
			newButton4.setLocation(350,50);
			thePanel.add(newButton4);

			Button newButton5 = new Button("Click on me!!!");
			newButton5.setSize(200,50);
			newButton5.setLocation(350,150);
			thePanel.add(newButton5);

			Button newButton6 = new Button("Click on me!!!");
			newButton6.setSize(200,50);
			newButton6.setLocation(350,250);
			thePanel.add(newButton6);

			Frame theFrame = new Frame("oPanel Test");
			theFrame.add(thePanel);
			theFrame.setSize(800,400);
			theFrame.show();
			// try { Thread.sleep(1000); } catch (Exception e) { }
			
			for (int count = 0; count < 200; count++) {
				newButton.setSize(newButton.getSize().width+2,
						  newButton.getSize().height+2);
				newButton.paint(newButton.getGraphics());
				try { Thread.sleep(1); } catch (Exception e) { }

				newButton2.setSize(newButton2.getSize().width+2,
						  newButton2.getSize().height+2);
				newButton2.paint(newButton2.getGraphics());
				try { Thread.sleep(1); } catch (Exception e) { }

				newButton3.setSize(newButton3.getSize().width+2,
						  newButton3.getSize().height+2);
				newButton3.paint(newButton3.getGraphics());
				try { Thread.sleep(1); } catch (Exception e) { }

				newButton4.setSize(newButton4.getSize().width+2,
						  newButton4.getSize().height+2);
				newButton4.paint(newButton4.getGraphics());
				try { Thread.sleep(1); } catch (Exception e) { }

				newButton5.setSize(newButton5.getSize().width+2,
						  newButton5.getSize().height+2);
				newButton5.paint(newButton5.getGraphics());
				try { Thread.sleep(1); } catch (Exception e) { }

				newButton6.setSize(newButton6.getSize().width+2,
						  newButton6.getSize().height+2);
				newButton6.paint(newButton6.getGraphics());
				try { Thread.sleep(1); } catch (Exception e) { }
			}
		}
}

////////////////////////////////////////////////////////////////////////
// Nothing after here.
