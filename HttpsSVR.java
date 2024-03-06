import com.sun.net.httpserver.*;
import javax.net.ssl.*;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.security.KeyStore;
import java.time.format.DateTimeFormatter;  
import java.time.LocalDateTime;

public class HttpsSVR {
    public static void main(String[] args) throws Exception {
        String keystoreFile = "d:/ssl2/server-cert.p12";
        String keystorePassword = "andrewj";
        int port = 3000;

        SSLContext sslContext = createSSLContext(keystoreFile, keystorePassword);

        HttpsServer server = HttpsServer.create(new InetSocketAddress(port), 0);
        server.setHttpsConfigurator(new HttpsConfigurator(sslContext));
        server.createContext("/api/data", new MyHandler());
        server.setExecutor(null);
        server.start();

        System.out.println("Server listening on port " + port + " (HTTPS)");
    }

    private static SSLContext createSSLContext(String keystoreFile, String keystorePassword) throws Exception {
        char[] passphrase = keystorePassword.toCharArray();
        SSLContext sslContext = SSLContext.getInstance("TLS");

        KeyStore ks = KeyStore.getInstance("JKS");
        FileInputStream fis = new FileInputStream(keystoreFile);
        ks.load(fis, passphrase);
        KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
        kmf.init(ks, passphrase);
        TrustManagerFactory tmf = TrustManagerFactory.getInstance("SunX509");
        tmf.init(ks);

        sslContext.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);
        fis.close();
        return sslContext;
    }

    static class MyHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("POST".equals(exchange.getRequestMethod())) {
                InputStream inputStream = exchange.getRequestBody();
                byte[] requestBody = inputStream.readAllBytes();
                String data = new String(requestBody);

                DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");  
                LocalDateTime now = LocalDateTime.now(); 
                System.out.println(dtf.format(now) + " Data Received: ");

                System.out.println(data);

                String response = "You are receiving the response sent from an HTTPS Server";
                exchange.sendResponseHeaders(200, response.getBytes().length);
                OutputStream outputStream = exchange.getResponseBody();
                outputStream.write(response.getBytes());
                outputStream.close();
            } else {
                exchange.sendResponseHeaders(405, -1); // Method Not Allowed
            }
        }
    }
}