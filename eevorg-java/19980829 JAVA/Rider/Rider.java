package Rider;

import java.rmi.*;

public class Rider implements Remote {

    String name;

    public Rider(String name) {
        this.name = name;
    }

    public static void main(String[] args) {
        System.setSecurityManager(new RMISecurityManager());

        System.out.println("Creating new remote object");
        Rider bound = new Rider("derek");
        try {
            Naming.bind("Rider.derek", bound);              
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        System.out.println("Getting access to new remote object");
        Remote rem;
        try {
            rem = Naming.lookup("rmi:///Rider.derek");
            System.out.println("Object = " + rem);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
