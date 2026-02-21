package theWheel;

class NetworkEditor {
    oNetwork loadNetwork(String fileName) {
        return new oNetwork();
    }

    void saveNetwork(String fileName, oNetwork forNet) {
    }

    void mainMenu(oNetwork forNet) {
        oNetwork
    }

    public static void main(String args[]) {
        if (args.length < 2) {
            System.out.println("Usage: java NetworkEditor <name.wxl>");
            System.exit(0);
        }

        oNetwork theNetwork = loadNetwork(args[1]);
        mainMenu(theNetwork);
    }
}