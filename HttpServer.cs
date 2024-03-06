using System;
using System.IO;
using System.Net;
using System.Text;
using System.Text.Json;

namespace HttpServer
{
    class Program
    {
        static void Main(string[] args)
        {
            // Create the HTTP listener
            HttpListener listener = new HttpListener();
            listener.Prefixes.Add("http://10.1.1.1:3001/");

            // Start the listener
            listener.Start();
            Console.WriteLine("Server listening on 10.1.1.1:3001 (HTTP)");

            // Handle incoming requests
            while (true)
            {
                HttpListenerContext context = listener.GetContext();
                HttpListenerRequest request = context.Request;
                HttpListenerResponse response = context.Response;

                DateTime now = DateTime.Now;

                // Handle only POST requests to the '/api/data' route
                if (request.HttpMethod == "POST" && request.Url.AbsolutePath == "/api/data")
                {
                    using (StreamReader reader = new StreamReader(request.InputStream, request.ContentEncoding))
                    {
                        string body = reader.ReadToEnd();

                        Console.WriteLine(now);

                        // Parse and pretty print the JSON
                        JsonDocument jsonDocument = JsonDocument.Parse(body);
                        string prettyPrintedJson = JsonSerializer.Serialize(jsonDocument.RootElement, new JsonSerializerOptions { WriteIndented = true });
                        Console.WriteLine(prettyPrintedJson);

                        // Send the response
                        string responseMessage = "You are receiving the response sent from an HTTP Server";
                        byte[] responseBytes = Encoding.UTF8.GetBytes(responseMessage);
                        response.ContentType = "text/plain";
                        response.ContentLength64 = responseBytes.Length;
                        response.OutputStream.Write(responseBytes, 0, responseBytes.Length);
                    }
                }

                // Close the response after processing the request
                response.Close();
            }
        }
    }
}