package analysis;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.HashMap;

public class CountSightings {
	public static void main(String[] args)
	{
		HashMap<String, Integer> hmap = new HashMap<String, Integer>();
		
		//read file
		try
		{
			BufferedReader br = new BufferedReader(new FileReader("input.dat"));
			String line = br.readLine();
			
			while (line != null)
			{
				if (hmap.containsKey(line) == false)
				{
					hmap.put(line, 0);
				}
				
				line = br.readLine();
			}
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		
	    int cnt = 0;
	    for (String key : hmap.keySet())
	    {
	    	cnt++;
	    }
	    
	    System.out.println("cnt = " + cnt);
	}
}
