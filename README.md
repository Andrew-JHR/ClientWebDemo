# z/OS Client Web Enablement Toolkit Sample Programs and HTTPS Setup Guide 
This tooling demonstrates how to write programs in various languages that z/OS supports 
such as REXX, Assembler, C, COBOL and PLI to take advantage of the z/OS provided APIs:
Client Web Enablement Toolkit to let the legacy programs on z/OS act as a HTTP client to
conduct RESTful data transfers with other system who works as a HTTP server.

1. 'POST' method is used in the client programs.

2. The data to be POSTed is hard-coded in the program to simplify the logic. In real world,
   data to be POSTed should be read into the program instead.
   
3. Sample z/OS JAVA programs as well as JCLs that perform the same POST function also provided.
   Note that JAVA programs on z/OS are using the JVM and JAVA library services which are NOT
   part of the z/OS Client Web Enablement Toolkit.
   
4. The counterpart server side programs on Windows to talk to the clients on the mainframe
   are also provided in Python, Node.js, C#, JAVA and Open Liberty.
   
5. Comparable client side programs on Windows in Python, JavaScript, C#, JAVA are also provided
   for a comparison.
   
6. The testing environment on the mainframe is using CCSID 937(Traditional Chinese) as the code.

7. Please refer to the Power Point file for further details. 

8. for running Open Liberty as the HTTP server on Windows, please also see another file:
   ReadMeFirst.txt in Liberty_Server.zip            



 
