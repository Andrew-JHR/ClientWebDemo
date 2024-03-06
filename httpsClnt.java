import java.io.BufferedReader;
import java.io.FileReader;
import java.io.OutputStream;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.security.KeyStore;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.net.URL;
import java.util.Scanner;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;

public class httpsClnt {

 public static void main(String[] args) {

   String data = "";
   try {
    File    file = new File("/u/andrewj/jsondata");
    Scanner scnr = new Scanner(file);
    while (scnr.hasNextLine()) {
        data = scnr.nextLine();
        System.out.println(data);
      } //while
    scnr.close();
    } catch (FileNotFoundException e) {
      System.out.println("read file error");
      e.printStackTrace();
    } //catch
   try {
    // Load the CA's PEM file into a KeyStore object
    String caFile = "/u/andrewj/ca-cert.pem";
    BufferedReader reader = new BufferedReader(new
    FileReader(caFile));
    StringBuilder builder = new StringBuilder();
    String line;
    while ((line = reader.readLine()) != null) {
      builder.append(line).append("\n");
    } //while
    reader.close();
    CertificateFactory cf = CertificateFactory.getInstance("X.509");
    X509Certificate caCert = (X509Certificate) cf.generateCertificate(new ByteArrayInputStream(builder.toString().getBytes()));
    KeyStore ks = KeyStore.getInstance(KeyStore.getDefaultType());
    ks.load(null, null);
    ks.setCertificateEntry("ca", caCert);

    // Create a TrustManagerFactory object that uses the KeyStore to
    // verify server certificates
    TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
    tmf.init(ks);

    // Create a SSLContext object that uses the TrustManagerFactory to
    // create a secure socket factory
    SSLContext sslContext = SSLContext.getInstance("TLS");
    sslContext.init(null, tmf.getTrustManagers(), null);

    // Set the SSLContext as the default SSLContext for the application
    HttpsURLConnection.setDefaultSSLSocketFactory(sslContext.getSocketFactory());

    // convert the data to a byte array
    byte[]postData = data.getBytes();

    // define the HTTPS connection
    URL url = new URL("https://10.1.1.1:3000/api/data");
    HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
    conn.setDoOutput(true);
    conn.setRequestMethod("POST");
    conn.setRequestProperty("Content-Type", "application/json");
    conn.setRequestProperty("Content-Length", Integer.toString(postData.length));


    // send the HTTPS request
    OutputStream os = conn.getOutputStream();
    os.write(postData);
    os.flush();
    os.close();

    // print the response code
    int responseCode = conn.getResponseCode();
    System.out.println("Response Code: " + responseCode);

    } catch (Exception e) {
      e.printStackTrace();
    } //catch

 } //main

} //httpsClnt
