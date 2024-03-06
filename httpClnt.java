import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.io.File;
import java.io.FileNotFoundException;
import java.util.Scanner;

public class httpClnt
{
  public static void main(String args[])
   {
     String data = "";
     try {
      File    file = new File("/u/andrewj/jsondata");
      Scanner scnr = new Scanner(file);
      while (scnr.hasNextLine()) {
          data = scnr.nextLine();
          System.out.println(data);
        }
      scnr.close();
      } catch (FileNotFoundException e) {
        System.out.println("read file error");
        e.printStackTrace();
      }
     try {
  //  String data = "{\"name\": \"JAVA Client\", \"age\": 29, ";
  //  data = data + "\"email\": \"James.Gosling@sun.com\", ";
  //  data = data + "\"address\": {\"street\": \"123 Main St\", ";
  //  data = data + "\"city\": \"Calgary\", \"state\": \"Alberta ";
  //  data = data + "Canata\",\"zip\": \"1995\"}}";

      // convert the data to a byte array
      byte[] postData = data.getBytes();
      // define the HTTP connection

      URL url = new URL("http://10.1.1.1:3001/api/data");
      HttpURLConnection conn = (HttpURLConnection) url.openConnection();
      conn.setDoOutput(true);
      conn.setRequestMethod("POST");
      conn.setRequestProperty("Content-Type","application/json");
      //conn.setRequestProperty("Content-Type","text/plain");
      conn.setRequestProperty("Content-Length",
      Integer.toString(postData.length));

      // send the HTTP request
      OutputStream os = conn.getOutputStream();
      os.write(postData);
      os.flush();
      os.close();

      // print the response code
      int responseCode = conn.getResponseCode();
      System.out.println("Resonse Code: " + responseCode);
     } catch (Exception e) {
       e.printStackTrace();
       }
   }
}
