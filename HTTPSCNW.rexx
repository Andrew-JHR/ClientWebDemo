//ANDREWJX JOB  CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//STEP1    EXEC PGM=IEBGENER
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  *
 /* rexx */

 /*********************************************************************/
 /*                                                                   */
 /* Main application starts here.                                     */
 /*                                                                   */
 /*********************************************************************/

 /* Provide access to TSO commands */
 Address TSO

 /* Make the HWTHTTP host environment available */
 Call hwtcalls on

 /* Initialise some variables we use */
 DiagArea. = ''
 Messages. = ''
 ReturnCode = 0
 ReqHandle = 0
 ConnectHandle = 0
 HttpStatusCode = 0
 HttpReasonCode = 0
 ResponseBody = ''

 Req  = '{"name": "Mainframe REXX", "age": 59,'
 Req  = Req  || '"email": "mainframe.zos@ibm.com", '
 Req  = Req  || '"address": {"street": "123 Main St", '
 Req  = Req  || '"city": "Taipei", "state": "Taiwan", '
 Req  = Req  || '"zip": "1964"}}'

 url = 'https://10.1.1.1'
 port = 3000
 path = '/api/data/'
 KeyRing = 'CLNTWEB'

 /*sslTraceFile = '/u/andrewj/ssltrace.bin' */

 /* Initialise some HWT constants */
 Address hwthttp "hwtconst" "ReturnCode" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwtconst"

 /*
  * Initialise a connection
  */

 /* Tell HWT we are creating a connection handle */
 HandleType = HWTH_HANDLETYPE_CONNECTION
 Address hwthttp "hwthinit" "ReturnCode" ,
                 "HandleType" "ConnectHandle" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwthinit (connection)"


 /*
  * Setup the connection options
  */

 /* Uncomment to enable debug messages */
 Call SetConnOpt "HWTH_OPT_VERBOSE", "HWTH_VERBOSE_ON"

 /* Connection URI (hostname really) */
 Call SetConnOpt "HWTH_OPT_URI", url

 /* Connection port                  */
 Call SetConnOpt "HWTH_OPT_PORT", port

 /* Timeout on the send after 10 seconds */
 Call SetConnOpt "HWTH_OPT_SNDTIMEOUTVAL", 10

 /* Timeout on the receive after 10 seconds */
 Call SetConnOpt "HWTH_OPT_RCVTIMEOUTVAL", 10

 /* Want to use SSL */
 Call SetConnOpt "HWTH_OPT_USE_SSL", "HWTH_SSL_USE"

 /* Specify the output trace file */
 /*Call SetConnOpt "HWTH_OPT_SSLTRACE", sslTraceFile */

 /* Use a SAF key ring */
 Call SetConnOpt "HWTH_OPT_SSLKEYTYPE","HWTH_SSLKEYTYPE_KEYRINGNAME"

 /* Use this key ring */
 Call SetConnOpt "HWTH_OPT_SSLKEY", KeyRing
 /* Call SetConnOpt "HWTH_OPT_SSLKEY", "ANDREWJ/CLNTWEB" */

 /* Force use of TLS 1.2 */
 Call SetConnOpt "HWTH_OPT_SSLVERSION", "HWTH_SSLVERSION_TLSv12"

 /* Perform the connect */
 Address hwthttp "hwthconn" "ReturnCode" "ConnectHandle" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwthconn"

 /* Confirm the request body */
 Say Req

 /* Initialise the request */
 HandleType = HWTH_HANDLETYPE_HTTPREQUEST
 Address hwthttp "hwthinit" "ReturnCode" ,
                 "HandleType" "ReqHandle" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwthinit (request)"


 /*
  * Setup the request options
  */

 /* Setup list of headers */
 sList = 0
   headerContentType = 'Content-type: application/json'
 /*headerContentType = 'Content-type: text/plain'*/

 Address hwthttp "hwthslst" "ReturnCode" ,
                 "ReqHandle" "HWTH_SLST_NEW" "sList" ,
                 "headerContentType" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwthslst (new)"

 /* HTTP POST request */
 Call SetReqOpt "HWTH_OPT_REQUESTMETHOD", "HWTH_HTTP_REQUEST_POST"

 /* Request path */
 Call SetReqOpt "HWTH_OPT_URI", path

 /* Use the HTTP headers list we have created */
 Call SetReqOpt "HWTH_OPT_HTTPHEADERS", sList

 /* Translate to ASCII outbound please */
 Call SetReqOpt "HWTH_OPT_TRANSLATE_REQBODY", ,
                "HWTH_XLATE_REQBODY_E2A"

 /* Translate to EBCDIC inbound please */
 Call SetReqOpt "HWTH_OPT_TRANSLATE_RESPBODY", ,
                "HWTH_XLATE_RESPBODY_A2E"

 /*
   The following options take a reference to the internal Rexx
   string buffer, but Rexx does not allow us to pass arguments by
   references and we can therefore not use the handy SetReqOpt
   subroutine used above.
 */

 /* Use the request body we created earlier */
 Address hwthttp "hwthset" "ReturnCode" "ReqHandle" ,
         "HWTH_OPT_REQUESTBODY" "Req" "DiagArea."
 If ReturnCode \= 0 Then
     Call ShowError "hwthset HWTH_OPT_REQUESTBODY"

 /* Grab the response data into here */
 Address hwthttp "hwthset" "ReturnCode" "ReqHandle" ,
         "HWTH_OPT_RESPONSEBODY_USERDATA" "ResponseBody" "DiagArea."
 If ReturnCode \= 0 Then
     Call ShowError "hwthset HWTH_OPT_RESPONSEBODY_USERDATA"


 /* Perform the request */
 Address hwthttp "hwthrqst" "ReturnCode" ,
                 "ConnectHandle" "ReqHandle" ,
                 "HttpStatusCode" "HttpReasonCode" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwthrqst"

 /* Check for good HTTP response */
 If HttpStatusCode \= 200 Then Do

     /* Dump out the HTTP response code */
     Say "HTTP status" HttpStatusCode

     /* Dump out the HTTP reason code */
     Say "HTTP reason" HttpReasonCode

     /* Dump out the response body */
     Say "Response" ResponseBody

 End

 Say ResponseBody

 /* Free the request headers */
 Address hwthttp "hwthslst" "ReturnCode" ,
                 "ReqHandle" "HWTH_SLST_FREE" "sList" ,
                 "headerContentType" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwthslst (free)"

 /* Reset the request for next use */
 Address hwthttp "hwthrset" "ReturnCode" ,
                 "ReqHandle" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwthrset (free)"


 /*
  * Processing of messages complete.
  * Now clean up the various handles we have open.
  */

 /* Close the connection to Server*/
 Address hwthttp "hwthdisc" "ReturnCode" "ConnectHandle" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwthdisc"

 /* Free the work area associated with the request */
 Address hwthttp "hwthterm" "ReturnCode" "ReqHandle" ,
                 "HWTH_NOFORCE" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwthterm (request)"

 /* Free the work area associated with the connection */
 Address hwthttp "hwthterm" "ReturnCode" "ConnectHandle" ,
                 "HWTH_NOFORCE" "DiagArea."

 If ReturnCode \= 0 Then Call ShowError "hwthterm (connection)"


 /* All complete */
 Exit 0


 /*********************************************************************/
 /*                                                                   */
 /* Routine to remove the drudgery of setting HTTP connection options */
 /*                                                                   */
 /*********************************************************************/

 SetConnOpt:

 /* Input arguments */
 @optName  = Arg(1)
 @optValue = Arg(2)

 /* Clear current status */
 ReturnCode = -1
 DiagArea. = ''

 /* Perform the call */
 Address hwthttp "hwthset" "ReturnCode" "ConnectHandle" ,
                 "@optName" "@optValue" "DiagArea."

 /* Check for good return */
 If ReturnCode \= 0 Then Call ShowError "hwthset (conn) " || @optName

 /* All complete */
 Return


 /*********************************************************************/
 /*                                                                   */
 /* Routine to remove the drudgery of setting HTTP request options    */
 /*                                                                   */
 /*********************************************************************/

 SetReqOpt:

 /* Input arguments */
 @optName  = Arg(1)
 @optValue = Arg(2)

 /* Clear current status */
 ReturnCode = -1
 DiagArea. = ''

 /* Perform the call */
 Address hwthttp "hwthset" "ReturnCode" "ReqHandle" ,
                 "@optName" "@optValue" "DiagArea."

 /* Check for good return */
 If ReturnCode \= 0 Then Call ShowError "hwthset (req) " || @optName

 /* All complete */


 Return


 /*********************************************************************/
 /*                                                                   */
 /* Displays the diagnostic data following a bad function call and    */
 /* terminates the runtime with RC=8.                                 */
 /*                                                                   */
 /*********************************************************************/

 ShowError: Procedure Expose ReturnCode DiagArea.

 /* Pull in the function name and diagnostic data */
 @fn = Arg(1)

 /* Keep track of the sign of the return code (D2X must be 0 or +ve) */
 If ReturnCode >= 0 Then SignReturnCode = '' ; Else SignReturnCode = '-'

 /* Say what went wrong */
 Say @fn || ,
     ": RC " || ReturnCode || ,
     "=" || SignReturnCode || "'" || D2X(ABS(ReturnCode)) || "'x"

 /* Dump out the error */
 Say "Service =" DiagArea.HWTH_Service
 Say "Reason  =" DiagArea.HWTH_ReasonCode
 Say "Desc    =" Strip(DiagArea.HWTH_ReasonDesc,,'00'x)

 /* Terminate the runtime */
 Exit 8

 Return
/*
//SYSUT2   DD  UNIT=SYSDA,DISP=(NEW,CATLG),
//         DSN=&&REXX(XX),
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000),SPACE=(TRK,(1,1,1))
//SYSIN    DD  DUMMY
//*
//STEP2    EXEC PGM=IKJEFT01
//SYSEXEC  DD  DSN=&&REXX,DISP=(OLD,DELETE)
//SRLLST   DD  SYSOUT=*
//JCLLST   DD  SYSOUT=(A,INTRDR)
//SYSPRINT DD  SYSOUT=*
//SYSTSPRT DD  SYSOUT=*
//SYSTSIN  DD  *
  %XX
/*
//
