package theWheel;

import java.awt.*;
import java.awt.event.*;

class WindowCloser
    extends WindowAdapter {
        public WindowCloser() { }
        public WindowCloser(Window w) {
            w.addWindowListener(this);
        }
        public void windowClosing( WindowEvent evt ) {
            Window w = evt.getWindow();
            w.dispose();
            System.exit(0);
        }
}