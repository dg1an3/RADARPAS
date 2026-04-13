package theWheel;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.*;

class oNetwork {

    public Vector nodes = new Vector();
    
    int lastNode = 0;
    o getRandomNode() {
        return (o) nodes.elementAt(lastNode++);
    }

    o[] getTriad() {
        o[] triad = new o[3];
        triad[0] = getRandomNode();
        triad[1] = getRandomNode();
        triad[2] = getRandomNode();
        return triad;
    }

    void loadNetwork(String fileName) {
    }

    void saveNetwork(String fileName) {
    }
}