package theWheel;

import java.awt.*;
import java.awt.event.*;

class oTriadView extends Frame {

    oNetwork myNet;

    o[] triad;

    Button buttonLeft = new Button("Button1");
    ActionListener buttonLeftPressed = new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                System.out.println("buttonLeft pressed.");
                buttonLeft.setLabel(triad[0].getLabel());
            }
        };
    { buttonLeft.addActionListener(buttonLeftPressed); }

    Button buttonRight = new Button("Button2");
    ActionListener buttonRightPressed = new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                System.out.println("buttonLeft pressed.");
                buttonRight.setLabel(triad[0].getLabel());
            }
        };
    { buttonRight.addActionListener(buttonRightPressed); }

    Button buttonCenter = new Button("Button3");
    ActionListener buttonCenterPressed = new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                System.out.println("buttonCenter pressed.");
                buttonCenter.setLabel(triad[0].getLabel());
            }
        };
    { buttonCenter.addActionListener(buttonCenterPressed); }

    oTriadView(oNetwork forNet) {
        super("TriadView");
        myNet = forNet;
        triad = forNet.getTriad();
        setLayout(new FlowLayout());
        add(buttonLeft);
        add(buttonRight);
        add(buttonCenter);
        setSize(200,100);
        new WindowCloser(this);
    }

    public static void main(String args[]) {
        /* if (args.length < 2) {
            System.out.println("Usage: java NetworkEditor <name.wxl>");
            System.exit(0);
        } */

        oNetwork theNetwork = new oNetwork();
        theNetwork.nodes.addElement(new o("Mom"));
        theNetwork.nodes.addElement(new o("Dad"));
        theNetwork.nodes.addElement(new o("TV"));
        /* theNetwork.loadNetwork(args[1]); */
        oTriadView theTC = new oTriadView(theNetwork);
        theTC.show();
    }
}