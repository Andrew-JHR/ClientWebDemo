//ANDREWJB JOB CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID,REGION=0M
//IGY      JCLLIB ORDER=IGY.SIGYPROC
//DOCLG    EXEC PROC=IGYWCLG,
//       PARM.COBOL='LIB',
//       PARM.LKED='REUS(RENT)',
//       PARM.GO='/POSIX(ON)'
//COBOL.STEPLIB DD DISP=SHR,DSN=IGY.SIGYCOMP
//COBOL.SYSLIB  DD DISP=SHR,DSN=ANDREWJ.SOURCE.MAC
//COBOL.SYSIN   DD *
       IDENTIFICATION                  DIVISION.
       PROGRAM-ID.                     HTTPSCNW.
      *----------------------------------------------------------------*
      *                                                                *
      *    E N V I R O N M E N T    D I V I S I O N                    *
      *                                                                *
      *----------------------------------------------------------------*
       ENVIRONMENT                     DIVISION.
       CONFIGURATION                   SECTION.
       SOURCE-COMPUTER.                IBM-2828.
       OBJECT-COMPUTER.                IBM-2828.
       INPUT-OUTPUT                    SECTION.
       FILE-CONTROL.
      *----------------------------------------------------------------*
      *                                                                *
      *    D A T A   D I V I S I O N                                   *
      *                                                                *
      *----------------------------------------------------------------*
       DATA                            DIVISION.
       FILE                            SECTION.
      *
      *----------------------------------------------------------------*
      *                                                                *
      *    W O R K I N G - S T O R A G E   S E C T I O N               *
      *                                                                *
      *----------------------------------------------------------------*
       WORKING-STORAGE                SECTION.
       01  HEADERTYPE               PIC X(30)  VALUE
           'Content-type: application/json'.
       01  URI                      PIC X(16)  VALUE 'https://10.1.1.1'.
       01  PATH                     PIC X(10)  VALUE '/api/data/'.
       01  KEYRING                  PIC X(7)   VALUE 'CLNTWEB'.
       01  REQ                      PIC X(152) VALUE
           '{"name":"Mainframe COBOL Client","age": 59,"email":"mainfram
      -    'e@ibm.com","address":{"street":"123 Main St","city":"Taipei"
      -    ',"State":"Taiwan","zip":"1960"}}'.
       01  PORT                     PIC 9(9) Binary Value 3000.
       01  TIMEOUT                  PIC 9(9) Binary Value 10.

      ******************************************************
      * Global vars required for majority of HTTP services
      ******************************************************
       01 Conn-Handle   Pic X(12) Value Zeros.
       01 Rqst-Handle   Pic X(12) Value Zeros.
       01 Diag-Area     Pic X(136) Value Zeros.

      *******************************************************
      * Slist is used to pass custom HTTP headers on request
      *******************************************************
       01 Slist-Handle  Pic 9(9) Binary Value 0.

      ***************************************
      * Dummy vars used by HWTHSET service
      ***************************************
       01 option-val-char    Pic X(999) Value Spaces.
       01 option-val-numeric Pic 9(9) Binary Value 0.
       01 option-val-addr    Pointer Value Null.
       01 option-val-len     Pic 9(9) Binary Value 0.

      ***************************************************
      * Function pointers used to setup exit (callback)
      * routines for response body
      ***************************************************
       01 bdy-callback-ptr Function-Pointer Value Null.

      ******************************************************
      * Response status code and Content-Length response
      * header (value) become accessible to either or both
      * exit routines via udata struct pointer fields
      ******************************************************
       01 http-response-code   Pic 9(3) Binary Value 0.
       01 http-content-length  Pic X(9) Value Spaces.

      ******************************************************
      * Data passed to the response body exit routine
      ******************************************************
       01 bdy-udata.
         05 bdy-udata-eye    Pic X(8) Value 'BDYUDATA'.
         05 bdy-contlen-ptr  Pointer value Null.

       01 request-status-flag    Pic 9.
         88 request-successful   Value 1.
         88 request-unsuccessful Value 0.

      ****************************************************
      * Toolkit (IDF file) copybook inclusion
      ****************************************************
         COPY HWTHICOB.
      *----------------------------------------------------------------*
      *                                                                *
      *    P R O C E D U R E                                           *
      *                                                                *
      *----------------------------------------------------------------*
       PROCEDURE                       DIVISION.
       Begin.

           Display "HTTP Web Enablement Toolkit in COBOL Start".
      *************************************************
      * Initialize and setup the connection handle to
      * reference the server
      *************************************************
           Perform Setup-Connection

             If (HWTH-OK)
      *************************************************
      * Connection handle setup was successful so now
      * attempt to connect to the server
      *************************************************
               Perform Connect

               If (HWTH-OK)
      *************************************************
      * We were able to connect so now initialize
      * and setup the request handle(s)
      *************************************************
                 Perform Setup-Request

                 If (HWTH-OK)
      ***********************************
      * Attempt to issue a POST request
      ***********************************
                   Display "Issuing POST request to 10.1.1.1"
                   Perform Issue-Request

      *************************************************
      * The connection and request handle can be
      * re-used for further requests. You can either
      * modify the attributes of the existing request
      * handle or create various other request handles.
      * Once the request handle(s) is no longer needed,
      * the resources obtained need to be cleaned up.
      *************************************************
                   Perform Cleanup-Request-Handle
                   End-If

      *************************************************
      * All done with requests against the server,
      * so disconnect from the server before proceeding
      * to clean up any resources obtained for the
      * connection.
      *************************************************
                 Perform Disconnect
                 End-If

      ********************************************
      * Clean up any resources obtained for the
      * connection instance.
      ********************************************
               Perform Cleanup-Connection-Handle
               End-If

           Display "HTTP Web Enablement Toolkit in COBOL End."

           STOP    RUN.

      ****************************************************************
      * Function: Setup-Connection                                   *
      *                                                              *
      *           Initializes and primes the connection handle.      *
      *           If any toolkit service fails, the function will    *
      *           surface the diagnostic area contents.              *
      ****************************************************************
       Setup-Connection.

      ***************************************************
      * Initialize the work area and retrieve a handle
      * for the connection.
      ***************************************************
           Set HWTH-HANDLETYPE-CONNECTION to true

           Call "HWTHINIT" using
             HWTH-RETURN-CODE
             HWTH-HANDLETYPE
             Conn-Handle
             HWTH-DIAG-AREA

           If Not (HWTH-OK)
             Display "FAILED: HWTHINIT for connection"
             Call "DSPHDIAG" using
                  HWTH-RETURN-CODE
                  HWTH-DIAG-AREA
           End-If

           If HWTH-OK
      ****************************************
      * Turn on verbose tracing. The default
      * for HTTP/HTTPS enabler is off
      ****************************************
             Set HWTH-OPT-VERBOSE to true
             Set HWTH-VERBOSE-ON to true
             Set option-val-addr to address of HWTH-VERBOSE
             Compute option-val-len = function length (HWTH-VERBOSE)

             Call "HWTHSET" using
                          HWTH-RETURN-CODE
                          Conn-Handle
                          HWTH-Set-OPTION
                          option-val-addr
                          option-val-len
                          HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET verbose option"
               Call "DSPHDIAG" using
                    HWTH-RETURN-CODE
                    HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      ****************************************
      * Set the connection URI for the server
      ****************************************
             Set HWTH-OPT-URI to true
             Move URI to option-val-char
             Set option-val-addr to address of option-val-char
             Compute option-val-len = function length (URI)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            Conn-Handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET uri option"
               Call "DSPHDIAG" using
                    HWTH-RETURN-CODE
                    HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      *****************************************************
      * Set the port number
      *****************************************************
             Set HWTH-OPT-PORT to true
             Move PORT to option-val-numeric
             Set option-val-addr to address of option-val-numeric
             Compute option-val-len =
                 function length (option-val-addr)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            Conn-Handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET port option"
               Call "DSPHDIAG" using
                    HWTH-RETURN-CODE
                    HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      *****************************************************
      * Set the timeout for sending
      *****************************************************
             Set HWTH-OPT-SNDTIMEOUTVAL to true
             Move TIMEOUT to option-val-numeric
             Set option-val-addr to address of option-val-numeric
             Compute option-val-len =
                 function length (option-val-addr)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            Conn-Handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET send timeout option"
               Call "DSPHDIAG" using
                    HWTH-RETURN-CODE
                    HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      *****************************************************
      * Set the timeout for receiving
      *****************************************************
             Set HWTH-OPT-RCVTIMEOUTVAL to true
             Move TIMEOUT to option-val-numeric
             Set option-val-addr to address of option-val-numeric
             Compute option-val-len =
                 function length (option-val-addr)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            Conn-Handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET receive timeout option"
               Call "DSPHDIAG" using
                    HWTH-RETURN-CODE
                    HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      *****************************************************
      * Set to use SSL
      *****************************************************
             Set HWTH-OPT-USE-SSL to true
             Set HWTH-SSL-USE to true
             Set option-val-addr to address of HWTH-USESSL
             Compute option-val-len =
                 function length (HWTH-USESSL)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            Conn-Handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET use ssl option"
               Call "DSPHDIAG" using
                    HWTH-RETURN-CODE
                    HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      *****************************************************
      * Set to use a SAF keyring
      *****************************************************
             Set HWTH-OPT-SSLKEYTYPE to true
             Set HWTH-SSLKEYTYPE-KEYRINGNAME to true
             Set option-val-addr to address of HWTH-SSLKEYTYPE
             Compute option-val-len =
                 function length (HWTH-SSLKEYTYPE)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            Conn-Handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET use SAF keyring option"
               Call "DSPHDIAG" using
                    HWTH-RETURN-CODE
                    HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      *****************************************************
      * Set the keyring
      *****************************************************
             Set HWTH-OPT-SSLKEY to true
             Move KEYRING to option-val-char
             Set option-val-addr to address of option-val-char
             Compute option-val-len = function length (KEYRING)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            Conn-Handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET set keyring option"
               Call "DSPHDIAG" using
                    HWTH-RETURN-CODE
                    HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      *****************************************************
      * Set to use TLS 1.2
      *****************************************************
             Set HWTH-OPT-SSLVERSION to true
             Set HWTH-SSLVERSION-TLSV12 to true
             Set option-val-addr to address of HWTH-SSLVERSION
             Compute option-val-len = function length (HWTH-SSLVERSION)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            Conn-Handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET use tls1.2 option"
               Call "DSPHDIAG" using
                    HWTH-RETURN-CODE
                    HWTH-DIAG-AREA
             End-If
           End-If
           .

      ****************************************************************
      *                                                              *
      * Function: Connect                                            *
      *                                                              *
      *   Issues the hwthconn service and performs error checking    *
      ****************************************************************
       Connect.

           Call "HWTHCONN" using
             HWTH-RETURN-CODE
             Conn-Handle
             HWTH-DIAG-AREA

           If Not (HWTH-OK)
             Display "FAILED: HWTHCONN connect attempt"
             Call "DSPHDIAG" using
                             HWTH-RETURN-CODE
                             HWTH-DIAG-AREA
           End-If
           .

      ****************************************************************
      * Function: Setup-Request                                      *
      *                                                              *
      *           Initializes and primes the request handle.         *
      *           If any toolkit service fails, the function will    *
      *           surface the diagnostic area contents.              *
      ****************************************************************
       Setup-Request.

      **************************************************
      * Initialize the work area and retrieve a handle
      * for the request
      **************************************************
           Set HWTH-HANDLETYPE-HTTPREQUEST to true
           Call "HWTHINIT" using
             HWTH-RETURN-CODE
             HWTH-HANDLETYPE
             Rqst-Handle
             HWTH-DIAG-AREA

           If Not (HWTH-OK)
             Display "FAILED: HWTHINIT for request"
             Call "DSPHDIAG" using
                             HWTH-RETURN-CODE
                             HWTH-DIAG-AREA
           End-If

           If HWTH-OK
      ****************************************************************
      * Create a brand new SLST and specify the first header to be a *
      * "Content-Type" header that informs the server about the      *
      * nature of the request body data sent with the POST request.  *
      ****************************************************************
             Move HEADERTYPE to option-val-char
             Compute option-val-len = Length of HEADERTYPE
             Set option-val-addr to address of option-val-char
             Set HWTH-SLST-NEW to true

             Call "HWTHSLST" using
               HWTH-RETURN-CODE
               rqst-handle
               HWTH-SLST-FUNCTION
               Slist-Handle
               option-val-addr
               option-val-len
               HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSLST build Slist"
               Call "DSPHDIAG" using
                               HWTH-RETURN-CODE
                               HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      **************************************************
      * Specify the HTTP method type
      **************************************************
             Set HWTH-OPT-REQUESTMETHOD to true
             Set HWTH-HTTP-REQUEST-POST to true
             Set option-val-addr to address of HWTH-REQUESTMETHOD
             Compute option-val-len =
               function length (HWTH-REQUESTMETHOD)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            rqst-handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET for request method"
               Call "DSPHDIAG" using
                               HWTH-RETURN-CODE
                               HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      **************************************************
      * Set the request URI
      **************************************************
             Set HWTH-OPT-URI to true
             Move PATH to option-val-char
             Set option-val-addr to address of option-val-char
             Compute option-val-len = function length (PATH)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            rqst-handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET for uri option"
               Call "DSPHDIAG" using
                               HWTH-RETURN-CODE
                               HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      ***************************************************************
      * Whether or not to supply request headers of our own making  *
      * depends upon the request (perhaps more upon the endpoint).  *
      * In this particular case, we are compelled to do so (for     *
      * reasons explained in the sequel).                           *
      ***************************************************************
             Set HWTH-OPT-HTTPHEADERS to true
             Set option-val-addr to address of Slist-Handle
             Compute option-val-len = function length(Slist-Handle)
             Display "** Set HWTH-OPT-HTTPHEADERS for request"
             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            rqst-handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET headers option"
               Call "DSPHDIAG" using
                               HWTH-RETURN-CODE
                               HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      **************************************************
      * Automatically convert the request body from
      * EBCDIC to ASCII
      **************************************************
             Set HWTH-OPT-TRANSLATE-REQBODY to true
             Set HWTH-XLATE-REQBODY-E2A to true
             Set option-val-addr to address of HWTH-XLATE-REQBODY
             Compute option-val-len =
                 function length (HWTH-XLATE-REQBODY)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            rqst-handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET for translate option"
               Call "DSPHDIAG" using
                               HWTH-RETURN-CODE
                               HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      **************************************************
      * Automatically convert the response body from
      * ASCII to EBCDIC
      **************************************************
             Set HWTH-OPT-TRANSLATE-RESPBODY to true
             Set HWTH-XLATE-RESPBODY-A2E to true
             Set option-val-addr to address of HWTH-XLATE-RESPBODY
             Compute option-val-len =
                 function length (HWTH-XLATE-RESPBODY)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            rqst-handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET for translate option"
               Call "DSPHDIAG" using
                               HWTH-RETURN-CODE
                               HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      **************************************************
      * Set the request body to send
      **************************************************
             Set HWTH-OPT-REQUESTBODY to true
             Move REQ to option-val-char
             Set option-val-addr to address of option-val-char
             Compute option-val-len = function length (REQ)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            rqst-handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET for request body"
               Call "DSPHDIAG" using
                               HWTH-RETURN-CODE
                               HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      *********************************************************
      * Set the response exit callback routine. This is the
      * address of the routine that is to receive control
      * if there is a response body returned by the server.
      *********************************************************
             Set HWTH-OPT-RESPONSEBODY-EXIT to true
             Set bdy-callback-ptr to ENTRY "HWTHBDYX"
             Set option-val-addr to address of bdy-callback-ptr
             Compute option-val-len =
                 function length (bdy-callback-ptr)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            rqst-handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET for response body exit"
               Call "DSPHDIAG" using
                               HWTH-RETURN-CODE
                               HWTH-DIAG-AREA
             End-If
           End-If

           If HWTH-OK
      *********************************************************
      * Initialize user data area pointers to allow
      * the response body exit to consult values from
      * the main program
      *********************************************************
             Set bdy-contlen-ptr to address of http-content-length

      *********************************************************
      * Establish the user data area as a parameter to
      * the response body exit
      *********************************************************
             Set HWTH-OPT-RESPONSEBODY-USERDATA to true
             Set option-val-addr to address of bdy-udata
             Compute option-val-len = function length(bdy-udata)

             Call "HWTHSET" using
                            HWTH-RETURN-CODE
                            rqst-handle
                            HWTH-Set-OPTION
                            option-val-addr
                            option-val-len
                            HWTH-DIAG-AREA

             If Not (HWTH-OK)
               Display "FAILED: HWTHSET for body exit udata"
               Call "DSPHDIAG" using
                               HWTH-RETURN-CODE
                               HWTH-DIAG-AREA
             End-If
           End-If
           .


      ****************************************************************
      *                                                              *
      * Function: Disconnect                                         *
      *                                                              *
      *   Issues the hwthdisc service and performs error checking    *
      ****************************************************************
       Disconnect.

           Call "HWTHDISC" using
             HWTH-RETURN-CODE
             Conn-Handle
             HWTH-DIAG-AREA

           If Not (HWTH-OK)
             Display "FAILED: HWTHDISC disconnect"
             Call "DSPHDIAG" using
                             HWTH-RETURN-CODE
                             HWTH-DIAG-AREA
           End-If
           .


      ****************************************************************
      *                                                              *
      * Function: Issue-Request                                      *
      *                                                              *
      *   Issues the hwthrqst service and performs error checking    *
      ****************************************************************
       Issue-Request.

           Call "HWTHRQST" using
             HWTH-RETURN-CODE
             Conn-Handle
             Rqst-Handle
             HWTH-DIAG-AREA

           If Not (HWTH-OK)
             Display "FAILED: HWTHRQST request"
             Call "DSPHDIAG" using
                             HWTH-RETURN-CODE
                             HWTH-DIAG-AREA
           End-If
           .


      ****************************************************************
      *                                                              *
      * Function: Cleanup-Connection-Handle                          *
      *                                                              *
      *   Cleans up the resources that were obtained earlier in      *
      *   Setup-Connection, by issuing the HWTHTERM service.         *
      ****************************************************************
       Cleanup-Connection-Handle.

           Set HWTH-NOFORCE to true.

           Call "HWTHTERM" using
             HWTH-RETURN-CODE
             Conn-Handle
             HWTH-FORCETYPE
             HWTH-DIAG-AREA.

           If Not (HWTH-OK)
             Display "FAILED: HWTHTERM connection handle"
             Call "DSPHDIAG" using
                             HWTH-RETURN-CODE
                             HWTH-DIAG-AREA
           End-If
           .

      ****************************************************************
      *                                                              *
      * Function: Cleanup-Request-Handle                             *
      *                                                              *
      *   Cleans up the resources that were obtained earlier in      *
      *   Setup-Request, by issuing the HWTHTERM service.            *
      ****************************************************************
       Cleanup-Request-Handle.

           Set HWTH-NOFORCE to true.

           Call "HWTHTERM" using
             HWTH-RETURN-CODE
             Rqst-Handle
             HWTH-FORCETYPE
             HWTH-DIAG-AREA.

           If Not (HWTH-OK)
             Display "FAILED: HWTHTERM request handle"
             Call "DSPHDIAG" using
                             HWTH-RETURN-CODE
                             HWTH-DIAG-AREA
           End-If
           .


       End Program HTTPSCNW.

      ****************************************************************
      * Program:  HWTHBDYX                                           *
      *           Callback routine used to process the response body *
      ****************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID HWTHBDYX.
       DATA DIVISION.

       WORKING-STORAGE SECTION.
       01 bodylen-value      Pic X(9) Value Spaces.

       LOCAL-STORAGE SECTION.

       LINKAGE SECTION.
       01 http-response  Pic X(20).
       01 exit-flags     Pic X(4).
       01 resp-body-ptr  Pointer.
       01 resp-body-len  Pic 9(9) Binary.
       01 bdy-udata-ptr  Pointer.
       01 bdy-udata-len  Pic 9(9) Binary.

       01 bdy-udata.
         05 bdy-udata-eye        Pic X(8).
         05 bdy-contlen-ptr      Pointer.

       01 http-content-length  Pic X(9).

       PROCEDURE DIVISION using http-response,
                                exit-flags,
                                resp-body-ptr,
                                resp-body-len,
                                bdy-udata-ptr,
                                bdy-udata-len.
       Begin.

      **********************************************
      * Establish addressability to the various
      * parameters and mapped structures
      **********************************************
           Set address of bdy-udata to bdy-udata-ptr
           Set address of http-content-length to bdy-contlen-ptr

      ******************************************************
      * Check the response body length against the value
      * of the Content-Length response header saved
      * earlier by the response headers callback
      ******************************************************
           Move resp-body-len to bodylen-value
           Inspect bodylen-value replacing leading '0' BY ' '.
           Display "Response body contains " bodylen-value " bytes"

           EXIT PROGRAM.

       End Program HWTHBDYX.


      ***************************************************************
      * Program:  DSPHDIAG                                          *
      *                                                             *
      * This program is used to display the current state of the    *
      * return code, reason code, and reason description.           *
      ***************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DSPHDIAG.
       DATA DIVISION.

       WORKING-STORAGE SECTION.
           COPY HWTHICOB.

       LOCAL-STORAGE SECTION.
       01 retcode-text Pic X(30) Value Spaces.
       01 rsncode-text Pic X(30) Value Spaces.

       LINKAGE SECTION.
       01 retcode      Pic 9(9) Binary.
       01 diag-area.
           05  srvcnum Pic 9(9) Binary.
           05  rsncode Pic 9(9) Binary.
           05  rsndesc Pic X(128).

       PROCEDURE DIVISION using
                          retcode,
                          diag-area.
       Begin.

           Compute HWTH-RETURN-CODE = retcode.

      ***************************************************************
      * Translate the return code integer into its text equivalent
      ***************************************************************
           Evaluate true
              When HWTH-OK
                Move "HWTH-OK" to retcode-text
              When HWTH-WARNING
                Move "HWTH-WARNING" to retcode-text
              When HWTH-HANDLE-INV
                Move "HWTH-HANDLE-INV" to retcode-text
              When HWTH-HANDLE-INUSE
                Move "HWTH-HANDLE-INUSE" to retcode-text
              When HWTH-HANDLETYPE-INV
                Move "HWTH-HANDLETYPE-INV" to retcode-text
              When HWTH-INACCESSIBLE-PARM
                Move "HWTH-INACCESSIBLE-PARM" to retcode-text
              When HWTH-CANNOT-OBTAIN-WORKAREA
                Move "HWTH-CANNOT-OBTAIN-WORKAREA" to retcode-text
              When HWTH-COMMUNICATION-ERROR
                Move "HWTH-COMMUNICATION-ERROR" to retcode-text
              When HWTH-CANNOT-INCREASE-WORKAREA
                Move "HWTH-CANNOT-INCREASE-WORKAREA" to retcode-text
              When HWTH-CANNOT-FREE-WORKAREA
                Move "HWTH-CANNOT-FREE-WORKAREA" to retcode-text
              When HWTH-CONNECTION-NOT-ACTIVE
                Move "HWTH-CONNECTION-NOT-ACTIVE" to retcode-text
              When HWTH-HSet-OPTIONVALADDR-INV
                Move "HWTH-HSet-OPTIONVALADDR-INV" to retcode-text
              When HWTH-HSet-OPTIONVALLEN-INV
                Move "HWTH-HSet-OPTIONVALLEN-INV" to retcode-text
              When HWTH-HSet-OPTION-INV
                Move "HWTH-HSet-OPTION-INV" to retcode-text
              When HWTH-HSet-OPTIONVALUE-INV
                Move "HWTH-HSet-OPTIONVALUE-INV" to retcode-text
              When HWTH-HSet-CONN-ALREADY-ACTIVE
                Move "HWTH-HSet-CONN-ALREADY-ACTIVE" to retcode-text
              When HWTH-HSLST-SLIST-INV
                Move "HWTH-HSLST-SLIST-INV" to retcode-text
              When HWTH-HSLST-FUNCTION-INV
                Move "HWTH-HSLST-FUNCTION-INV" to retcode-text
              When HWTH-HSLST-STRINGLEN-INV
                Move "HWTH-HSLST-STRINGLEN-INV" to retcode-text
              When HWTH-HSLST-STRINGADDR-INV
                Move "HWTH-HSLST-STRINGADDR-INV" to retcode-text
              When HWTH-HTERM-FORCEOPTION-INV
                Move "HWTH-HTERM-FORCEOPTION-INV" to retcode-text
              When HWTH-HCONN-CONNECT-INV
                Move "HWTH-HCONN-CONNECT-INV" to retcode-text
              When HWTH-HRQST-REQUEST-INV
                Move "HWTH-HRQST-REQUEST-INV" to retcode-text
              When HWTH-INTERRUPT-STATUS-INV
                Move "HWTH-INTERRUPT-STATUS-INV" to retcode-text
              When HWTH-LOCKS-HELD
                Move "HWTH-LOCKS-HELD" to retcode-text
              When HWTH-MODE-INV
                Move "HWTH-MODE-INV" to retcode-text
              When HWTH-AUTHLEVEL-INV
                Move "HWTH-AUTHLEVEL-INV" to retcode-text
              When HWTH-ENVIRONMENTAL-ERROR
                Move "HWTH-ENVIRONMENTAL-ERROR" to retcode-text
              When HWTH-UNSUPPORTED-RELEASE
                Move "HWTH-UNSUPPORTED-RELEASE" to retcode-text
              When HWTH-UNEXPECTED-ERROR
                Move "HWTH-UNEXPECTED-ERROR" to retcode-text
           End-evaluate

           If retcode-text is equal to Spaces
             Move 'Unknown return code' to retcode-text
           End-If

      ***************************************************************
      * Not all errors result in a reason code. Therefore, only
      * fill out the reason-code-text if the reason code is non-zero
      ***************************************************************
           If rsncode is not equal ZERO

             Move rsncode to HWTH-REASONCODE

             Evaluate true
               When HWTH-RSN-REDIRECTED
                 Move "HWTH-RSN-REDIRECTED" to rsncode-text
               When HWTH-RSN-NEEDED-REDIRECT
                 Move "HWTH-RSN-NEEDED-REDIRECT" to rsncode-text
               When HWTH-RSN-REDIRECT-XDOMAIN
                 Move "HWTH-RSN-REDIRECT-XDOMAIN" to rsncode-text
               When HWTH-RSN-REDIRECT-TO-HTTP
                 Move "HWTH-RSN-REDIRECT-TO-HTTP" to rsncode-text
               When HWTH-RSN-REDIRECT-TO-HTTPS
                 Move "HWTH-RSN-REDIRECT-TO-HTTPS" to rsncode-text
               When HWTH-RSN-NO-REDIRECT-LOCATION
                 Move "HWTH-RSN-NO-REDIRECT-LOCATION" to rsncode-text
               When HWTH-RSN-HDR-EXIT-ABORT
                 Move "HWTH-RSN-HDR-EXIT-ABORT" to rsncode-text
               When HWTH-RSN-TUNNEL-UNSUCCESSFUL
                 Move "HWTH-RSN-TUNNEL-UNSUCCESSFUL" to rsncode-text
               When HWTH-RSN-MALFORMED-CHNK-ENCODE
                 Move "HWTH-RSN-MALFORMED-CHNK-ENCODE" to rsncode-text
               When HWTH-RSN-COOKIE-STORE-FULL
                 Move "HWTH-RSN-COOKIE-STORE-FULL" to rsncode-text
               When HWTH-RSN-COOKIE-INVALID
                 Move "HWTH-RSN-COOKIE-INVALID" to rsncode-text
               When HWTH-RSN-COOKIE-STORE-INV-PARM
                 Move "HWTH-RSN-COOKIE-STORE-INV-PARM" to rsncode-text
               When HWTH-RSN-COOKIE-ST-INCOMPLETE
                 Move "HWTH-RSN-COOKIE-ST-INCOMPLETE" to rsncode-text
               When HWTH-RSN-COOKIE-ST-MALLOC-ERR
                 Move "HWTH-RSN-COOKIE-ST-MALLOC-ERR" to rsncode-text
               When HWTH-RSN-COOKIE-ST-FREE-ERROR
                 Move "HWTH-RSN-COOKIE-ST-FREE-ERROR" to rsncode-text
               When HWTH-RSN-COOKIE-ST-UNEXP-ERROR
                 Move "HWTH-RSN-COOKIE-ST-UNEXP-ERROR" to rsncode-text
               When HWTH-RSN-MALFORMED-REDIR-URI
                 Move "HWTH-RSN-MALFORMED-REDIR-URI" to rsncode-text
             End-Evaluate
           End-If

           Display "Return code: " retcode-text.
           Display "Service: " srvcnum.
           Display "Reason Code: " rsncode-text.
           Display "Reason Desc: " rsndesc.

       End Program DSPHDIAG.
/*
//LKED.SYSLIB  DD DISP=SHR,DSN=CEE.SCEELKED
//             DD DISP=SHR,DSN=CEE.SCEELKEX
//             DD DISP=SHR,DSN=SYS1.CSSLIB
//GO.SYSPRINT  DD SYSOUT=*
