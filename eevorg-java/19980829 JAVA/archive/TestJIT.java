import java.util.*;

class TestJIT {

	public static long test ( ) {
		int j;
		Date start = new Date();
		for (int i = 0; i < 1000000; i++)
			j = i*i;
		Date end = new Date();
		return end.getTime() - start.getTime();
	}
		
	public static void main( String args[] ) {
		String compiler = System.getProperty("java.compiler");
		System.out.println("The compiler is " + compiler);
		
		System.out.println("Lapse = " + test());
		Compiler.enable();
		boolean result = Compiler.compileClass(TestJIT.class);
		System.out.println("Compile result = " + result);
		System.out.println("Lapse = " + test());
	}
}
