using System;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

namespace HttpsClient
{
    class Program
    {
        static void Main()
        {
            try
            {
                // define the data to be sent
                string data = "{\"name\": \"CSharp\", \"age\": 23, \"email\": \"Anders.Hejlsberg@microsoft.com\", \"address\": {\"street\": \"123 Main St\", \"city\": \"Copenhagen\", \"state\": \"Denmark\", \"zip\": \"2000\"}}";

                // convert the data to a byte array
                byte[] postData = System.Text.Encoding.UTF8.GetBytes(data);

                // define the HTTP request
                ServicePointManager.ServerCertificateValidationCallback += ValidateServerCertificate;
                WebRequest request = WebRequest.Create("https://10.1.1.1:3000/api/data");
                request.Method = "POST";
                request.ContentType = "application/json";
                request.ContentLength = postData.Length;

                // send the HTTP request
                using (Stream dataStream = request.GetRequestStream())
                {
                    dataStream.Write(postData, 0, postData.Length);
                }

                // get the HTTP response
                using (WebResponse response = request.GetResponse())
                {
                    Console.WriteLine("Response Status: " + ((HttpWebResponse)response).StatusDescription);
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }
        }
        private static bool ValidateServerCertificate(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors)
        {
            if (sslPolicyErrors == SslPolicyErrors.None)
            {
                return true;
            }

            // Load the server's CA PEM file and validate the certificate chain
            string caPemFile = "Andrew's CA";
            X509Certificate2 caCert = new X509Certificate2(caPemFile);
            chain.ChainPolicy.ExtraStore.Add(caCert);
            bool chainIsValid = chain.Build(new X509Certificate2(certificate));

            return chainIsValid;
        }
    }
}