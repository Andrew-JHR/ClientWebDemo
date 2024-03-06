//ANDREWJC JOB    CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID,REGION=0M
//CBC      JCLLIB ORDER=CBC.SCCNPRC
//DOCLG    EXEC   PROC=CBCCBG,
//     PARM.COMPILE='LOCALE(ZH_TW.IBM-937)',
//     PARM.GO='POSIX(ON)/-v'
//COMPILE.SYSLIB  DD  DSN=SYS1.SIEAHDRV.H,DISP=SHR
//COMPILE.SYSIN   DD  *
 #define _OPEN_SYS_ITOA_EXT
 #pragma langlvl(extc99)
 #include <string.h>
 #include <stdio.h>
 #include <stdlib.h>
 #include <stdbool.h>
 #include "hwthic.h"

 char *HEADERTYPE = "Content-type: application/json";
 char *URI        = "https://10.1.1.1";
 char *PATH       = "/api/data/";
 char *KEYRING    = "CLNTWEB";

 char *REQ  = "{\"name\": \"Mainframe zOS C\", \"age\": 59, \
 \"email\": \"mainframe.zos@ibm.com\", \
 \"address\": {\"street\": \"123 Main St\", \
 \"city\": \"Taipei\", \"state\": \"Taiwan\", \
 \"zip\": \"1964\"}}";

 int   PORT    = 3000;
 int   TIMEOUT = 10;
 int   EXPECTED_HTTP_STATUS_CODE = 200;

 int ContentLength = 0;
 int HttpStatusCode = 0;

 HWTH_SLIST_TYPE SList;
 HWTH_SLIST_TYPE *SListPtr = &SList;

 /********************************************
  * Response exits, as defined in hwthic.h
  ********************************************/
 HWTHBDYX rbdyexit;

 /*************************************************************
  * Data area passed to a callback (exit) routine.  This can
  * have any size and content.  In this sample, we use it just
  * to provide access to variables known to the main program.
  *************************************************************/
 struct userdata {
       char eyecatcher[8];
       int  *HttpStatusCodePtr;
       int  *ContentLengthPtr;
       };

 struct userdata BdyUserdata;


 _Bool setupConnection( HWTH_HANDLE_TYPE *connectionHandlePtr,
                        int verbose );
 _Bool connect( HWTH_HANDLE_TYPE connectionHandle );

 _Bool setupRequest( HWTH_HANDLE_TYPE *requestHandlePtr );

 void issueRequest( HWTH_HANDLE_TYPE connectionHandle,
                    HWTH_HANDLE_TYPE requestHandle );

 void disconnect( HWTH_HANDLE_TYPE connectionHandle );

 void cleanupHandle( HWTH_HANDLE_TYPE handle );

 void printDiag( HWTH_RETURNCODE_TYPE *rcPtr,
                 HWTH_DIAGAREA_TYPE   *diagAreaPtr,
                 char *what );

 char *getMethodName( uint32_t apiMethodInt );

 _Bool setOptionFailed( HWTH_RETURNCODE_TYPE *rcPtr,
                        HWTH_DIAGAREA_TYPE   *diagAreaPtr,
                        char *what,
                  HWTH_HANDLE_TYPE *handlePtr );


 int main( int argc, char **argv ) {

  HWTH_HANDLE_TYPE connectionHandle;
  HWTH_HANDLE_TYPE requestHandle;
  _Bool verbose = false;
  char message[128];

  /*************************************
   * Check argument for Verbose
   *************************************/

  if ( argc > 1 ) {
    if ( strcmp( argv[1], "-v" ) == 0 )
        verbose = true;
    else {
     printf( "Invalid option %s specified.\nValid options: "
     "-v for verbose\n", argv[1] );
     return -1;
     }
  }

  printf( "HTTPS Client Web Toolkit in C Start\n" );

  /*************************************************
   * Initialize and setup the connection handle to
   * reference the server
   *************************************************/
  if ( setupConnection( &connectionHandle, verbose ) ) {
     /********************************************
      * Connection handle setup was successful so
      * now attempt to connect to the server
      ********************************************/
     if ( connect( connectionHandle ) ) {
        /********************************************
         * We were able to connect so now initialize
         * and setup a request handle
         ********************************************/
        if ( setupRequest( &requestHandle ) ) {
           char buffer[5];
           itoa(PORT,buffer,10);
           printf( "Issuing POST request to %s(%s)%s\n",
                    URI, buffer, PATH);

           issueRequest( connectionHandle,
                         requestHandle );

     /***************************************************
      * The connection and request handle can be re-used
      * for further requests. You can either modify
      * the attributes of the existing request handle or
      * create various other request handles. Once the
      * request handle(s) is no longer needed,
      * the resources obtained need to be cleaned up.
      ***************************************************/
           cleanupHandle( requestHandle );
           } /* endif request setup ok */

     /*****************************************************
      * All done with requests against the server, so
      * disconnect from the server before proceeding to
      * clean up any resources obtained for the connection.
      *****************************************************/
        disconnect( connectionHandle );
        } /* endif connected */

   /***********************************
    * Clean up any resources obtained
    * for the connection instance
    ***********************************/
     cleanupHandle( connectionHandle );
     } /* endif connection setup ok */

  printf("HTTPS Client Web Toolkit in C End\n");
  return 0;
  } /* end main */


 /****************************************************************
  * Function:  cleanupHandle()
  *
  * Clean up the resources that were obtained by previous call
  * to the service which initialized the input handle.
  ****************************************************************/
 void cleanupHandle( HWTH_HANDLE_TYPE handleIn ) {

  HWTH_RETURNCODE_TYPE rc = HWTH_OK;
  HWTH_DIAGAREA_TYPE diagArea;

  hwthterm( &rc,
            handleIn,
            HWTH_NOFORCE,
            &diagArea );

  if ( rc != HWTH_OK ) {
     printDiag( &rc,
                &diagArea,
                "HWTHTERM request - NO FORCE" );

    /******************************************
     * The initial termination request failed,
     * so we try brute force
     ******************************************/
     rc = HWTH_OK;

     hwthterm( &rc,
               handleIn,
               HWTH_FORCE,
               &diagArea );

     if ( rc != HWTH_OK )
        printDiag( &rc,
                   &diagArea,
                   "HWTHTERM request - FORCE" );
     } /* endif force required */
  } /* end function */


 /***************************************************
  * Function: setupConnection()
  *
  * Initialize and configure a connection handle.
  *
  * Return true if successful.  Surface failure
  * diagnostics and return false if otherwise.
  ***************************************************/
 _Bool setupConnection( HWTH_HANDLE_TYPE *connectionHandlePtr,
                        int verbose ) {

  char *lcharOptionVal;
  uint32_t intOption;
  uint32_t *intOptionPtr = &intOption;
  HWTH_RETURNCODE_TYPE rc = HWTH_OK;
  HWTH_DIAGAREA_TYPE diagArea;
  char message[128];

  /*****************************************
   * Initialize the work area and retrieve
   * a handle for the connection.
   *****************************************/
  hwthinit( &rc,
            HWTH_HANDLETYPE_CONNECTION,
            connectionHandlePtr,
            &diagArea );

  if ( rc != HWTH_OK ) {
     printDiag( &rc,
                &diagArea,
                "HWTHINIT for connection" );
     return false;
     }

  /********************************************
   * If requested, turn on verbose tracing.
   * The default for HTTP/HTTPS enabler is off.
   ********************************************/
  if (verbose) {
     intOption = HWTH_VERBOSE_ON;

     hwthset( &rc,
              *connectionHandlePtr,
              HWTH_OPT_VERBOSE,
              (void **) &intOptionPtr,
              sizeof(intOption),
              &diagArea );

     if ( setOptionFailed( &rc,
                           &diagArea,
                           "HWTHSET for connection - set verbose",
                           connectionHandlePtr ) )
        return false;
     } /* endif verbose trace */

  /*******************************************
   * Set the connection URI for the server.
   ******************************************/
  sprintf( message,
           "HWTHSET for connection - set URI %s",
           URI );
  lcharOptionVal = URI;
  hwthset( &rc,
           *connectionHandlePtr,
           HWTH_OPT_URI,
           (void**) &lcharOptionVal,
           strlen(lcharOptionVal),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        message,
                        connectionHandlePtr ) )
     return false;

  /*****************************************************************
   * Set port for the server
   *****************************************************************/
  intOption = PORT;
  hwthset( &rc,
           *connectionHandlePtr,
           HWTH_OPT_PORT,
           (void **) &intOptionPtr,
           sizeof(intOption),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET port number",
                        connectionHandlePtr ) )
     return false;

  /*****************************************************************
   * Set timeout for send
   *****************************************************************/

  intOption = TIMEOUT;
  hwthset( &rc,
           *connectionHandlePtr,
           HWTH_OPT_SNDTIMEOUTVAL,
           (void **) &intOptionPtr,
           sizeof(intOption),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET send time out",
                        connectionHandlePtr ) )
     return false;

  /*****************************************************************
   * Set timeout for receive
   *****************************************************************/

  intOption = TIMEOUT;
  hwthset( &rc,
           *connectionHandlePtr,
           HWTH_OPT_RCVTIMEOUTVAL,
           (void **) &intOptionPtr,
           sizeof(intOption),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET receive time out",
                        connectionHandlePtr ) )
     return false;

  /*****************************************************************
   * Set to use ssl
   *****************************************************************/

  intOption = HWTH_SSL_USE;
  hwthset( &rc,
           *connectionHandlePtr,
           HWTH_OPT_USE_SSL,
           (void **) &intOptionPtr,
           sizeof(intOption),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET use SSL",
                        connectionHandlePtr ) )
     return false;

  /*****************************************************************
   * Set to use a SAF keyring
   *****************************************************************/

  intOption = HWTH_SSLKEYTYPE_KEYRINGNAME;
  hwthset( &rc,
           *connectionHandlePtr,
           HWTH_OPT_SSLKEYTYPE,
           (void **) &intOptionPtr,
           sizeof(intOption),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET use SAF keyring",
                        connectionHandlePtr ) )
     return false;


  /*******************************************
   * Set the keyring.
   ******************************************/
  lcharOptionVal = KEYRING;
  hwthset( &rc,
           *connectionHandlePtr,
           HWTH_OPT_SSLKEY,
           (void**) &lcharOptionVal,
           strlen(lcharOptionVal),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET set the keyring name",
                        connectionHandlePtr ) )
     return false;

  /*****************************************************************
   * Set to use TLS V1.2
   *****************************************************************/

  intOption = HWTH_SSLVERSION_TLSV12;
  hwthset( &rc,
           *connectionHandlePtr,
           HWTH_OPT_SSLVERSION,
           (void **) &intOptionPtr,
           sizeof(intOption),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET use SAF keyring",
                        connectionHandlePtr ) )
     return false;

  return true;
  }    /* end function */


 /********************************************************
  * Function: setupRequest()
  *
  * Initialize and configure a request handle.
  *
  * Return true if successful.  Surface failure
  * diagnostics and return false if otherwise.
  ********************************************************/
 _Bool setupRequest( HWTH_HANDLE_TYPE *requestHandlePtr ) {

  uint32_t lintOptionVal;
  uint32_t *lintOptionValPtr = &lintOptionVal;
  int loptionExit;
  int *loptionExitAddr;
  char *lcharOptionVal;
  void *loptionValueAddr;
  HWTH_RETURNCODE_TYPE rc = HWTH_OK;
  HWTH_DIAGAREA_TYPE diagArea;
  char message[128];


  /*****************************************
   * Initialize the work area and retrieve
   * a handle for the request.
   *****************************************/
  hwthinit( &rc,
            HWTH_HANDLETYPE_HTTPREQUEST,
            requestHandlePtr,
            &diagArea );

  if ( rc != HWTH_OK ) {
     printDiag( &rc,
                &diagArea,
                "HWTHINIT for request" );
     return false;
     }

  /*****************************************************
   * Set up list of header
   ****************************************************/
  lcharOptionVal = HEADERTYPE;
  *SListPtr = NULL;
  sprintf( message,
           "HWTSLST new header list %s",
           getMethodName(lintOptionVal) );
  hwthslst( &rc,
           *requestHandlePtr,
           HWTH_SLST_NEW,
           SListPtr,
           (void**) &lcharOptionVal,
           strlen(lcharOptionVal),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        message,
                        requestHandlePtr ) )
     return false;

  /*****************************************************
   * Specify the HTTP method type, i.e. GET, POST,PUT
   ****************************************************/
  lintOptionVal = HWTH_HTTP_REQUEST_POST;
  sprintf( message,
           "HWTSET request method %s",
           getMethodName(lintOptionVal) );
  hwthset( &rc,
           *requestHandlePtr,
           HWTH_OPT_REQUESTMETHOD,
           (void**) &lintOptionValPtr,
           sizeof(lintOptionVal),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        message,
                        requestHandlePtr ) )
     return false;


  /************************
   * Set the request URI
   ************************/
  lcharOptionVal = PATH;
  sprintf( message,
           "HWTSET request uri %s",
           PATH );
  hwthset( &rc,
           *requestHandlePtr,
           HWTH_OPT_URI,
           (void**) &lcharOptionVal,
           strlen(lcharOptionVal),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        message,
                        requestHandlePtr ) )
     return false;

  /*****************************************************
   * Set Headers
   ****************************************************/
  sprintf( message,
           "HWTSET headers %s",
           getMethodName(lintOptionVal) );
  hwthset( &rc,
           *requestHandlePtr,
           HWTH_OPT_HTTPHEADERS,
           (void**) &SListPtr,
           sizeof(SList),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        message,
                        requestHandlePtr ) )
     return false;

  /**********************************************************
   * Request body should be automatically converted from
   * EBCDIC to ASCII
   *********************************************************/
  lintOptionVal = HWTH_XLATE_REQBODY_E2A;

  hwthset( &rc,
           *requestHandlePtr,
           HWTH_OPT_TRANSLATE_REQBODY,
           (void**) &lintOptionValPtr,
           sizeof(lintOptionVal),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET for request - translate to ASCII",
                        requestHandlePtr ) )
     return false;

  /**********************************************************
   * Response body should be automatically converted from
   * ASCII to EBCDIC (the default is no conversion)
   *********************************************************/
  lintOptionVal = HWTH_XLATE_RESPBODY_A2E;

  hwthset( &rc,
           *requestHandlePtr,
           HWTH_OPT_TRANSLATE_RESPBODY,
           (void**) &lintOptionValPtr,
           sizeof(lintOptionVal),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET for response- translate to EBCDIC",
                        requestHandlePtr ) )
     return false;


  /************************
   * Set the request data
   ************************/
  lcharOptionVal = REQ;
  sprintf( message,
           "HWTSET request data %s",
           PATH );
  hwthset( &rc,
           *requestHandlePtr,
           HWTH_OPT_REQUESTBODY,
           (void**) &lcharOptionVal,
           strlen(lcharOptionVal),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        message,
                        requestHandlePtr ) )
     return false;

  /**************************************************
   * Prepare the userdata area for the body exit,
   * and make it available to them on callback
   **************************************************/
  strcpy( BdyUserdata.eyecatcher, "BDYUDATA" );
  BdyUserdata.HttpStatusCodePtr = &HttpStatusCode;
  BdyUserdata.ContentLengthPtr = &ContentLength;
  lintOptionVal = (uint32_t)&BdyUserdata;

  hwthset( &rc,
           *requestHandlePtr,
           HWTH_OPT_RESPONSEBODY_USERDATA,
           (void**) &lintOptionValPtr,
           sizeof(lintOptionVal),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET for body exit userdata",
                        requestHandlePtr ) )
     return false;

  /********************************************************
   * Set the body exit (callback) routine.  This routine
   * receives control once if a response body is returned
   * by the web server.
   ********************************************************/
  loptionExit = (int) rbdyexit;
  loptionExitAddr = &loptionExit;

  hwthset( &rc,
           *requestHandlePtr,
           HWTH_OPT_RESPONSEBODY_EXIT,
           (void**) &loptionExitAddr,
           sizeof(loptionExit),
           &diagArea );

  if ( setOptionFailed( &rc,
                        &diagArea,
                        "HWTHSET for response body exit",
                        requestHandlePtr ) )
     return false;


  return true;
  } /* end function */


 /********************************************************
  * Function: connect()
  *
  * Connect to the web server using the settings which
  * were established via the connection handle.
  *
  * Return true if connection is established.  Surface
  * error diagnostics and return false if otherwise.
  ********************************************************/
 _Bool connect( HWTH_HANDLE_TYPE connectionHandle ) {

  HWTH_RETURNCODE_TYPE rc = HWTH_OK;
  HWTH_DIAGAREA_TYPE diagArea;
  char message[128];

  hwthconn( &rc,
            connectionHandle,
            &diagArea );

  if ( rc != HWTH_OK ) {
     sprintf( message,
              "HWTHCONN failed to setup a socket for %s",
              URI );
     printDiag( &rc, &diagArea, message );
     return false;
     }

  return true;
 } /* end function */


 /***********************************************************
  * Function: issueRequest()
  *
  * Make a request to the web server using the settings
  * which were established via the request handle.
  *
  * Surface error diagnostics if appropriate.
  ***********************************************************/
 void issueRequest( HWTH_HANDLE_TYPE connectionHandle,
                    HWTH_HANDLE_TYPE requestHandle ) {

  HWTH_RETURNCODE_TYPE rc = HWTH_OK;
  HWTH_DIAGAREA_TYPE diagArea;

  hwthrqst( &rc,
            connectionHandle,
            requestHandle,
            &diagArea );

  if ( rc != HWTH_OK )
     printDiag( &rc,
                &diagArea,
                "HWTHRQST for Http POST" );

 } /* end function */


 /********************************************************
  * Function: disconnect()
  *
  * Close the connection to the web server which was
  * established earlier via connect().
  *
  * Surface error diagnostics if appropriate.
  ********************************************************/
 void disconnect( HWTH_HANDLE_TYPE connectionHandle ) {

  HWTH_RETURNCODE_TYPE rc = HWTH_OK;
  HWTH_DIAGAREA_TYPE diagArea;

  hwthdisc( &rc,
            connectionHandle,
            &diagArea );

  if ( rc != HWTH_OK )
     printDiag( &rc,
                &diagArea,
                "HWTHDISC of connection/socket" );
 } /* end function */


 /***************************************
  * Function: printDiag()
  *
  * Output diagnostic information
  ***************************************/
 void printDiag( HWTH_RETURNCODE_TYPE *rcPtr,
                 HWTH_DIAGAREA_TYPE *diagAreaPtr,
                 char *whatFailed ) {

  printf( "FAILED: %s\n", whatFailed );
  printf( "Return Code: %d\n", *rcPtr );
  printf( "Service Id : %d\n", diagAreaPtr->HWTH_service );
  printf( "Reason Code: %d\n", diagAreaPtr->HWTH_reasonCode );
  printf( "Reason Desc: %s\n", diagAreaPtr->HWTH_reasonDesc );
 } /* end function */



 /***********************************************************
  * Response Body Exit: rbdyexit()
  *
  * This exit receives control (once) when a response body
  * is returned by the web server.
  **********************************************************/
 void rbdyexit( HWTH_STATUS_LINE_TYPE *httpResp,
                HWTH_RESP_EXIT_FLAGS_TYPE *exitFlags,
                char **respBody,
                uint32_t *respBodyLen,
                char **bodyUserData,
                uint32_t *bodyUserDataLen ) {

  /**************************************************
   * Use the passed userdata to access variables
   * known to main.
   **************************************************/
  struct userdata *P = *((struct userdata **)*bodyUserData);
  int *ContentLengthPtr = P->ContentLengthPtr;

  printf( "Response body contains %i bytes.\n", *respBodyLen );

 } /* end body exit */


 /*************************************************
  * Function: getMethodName()
  *
  * Returns a string representation of the HTTP
  * method indicated by the input constant
  *************************************************/
 char *getMethodName(uint32_t apiMethodInt) {
  /*
   * defined in hwthic.h
   *
   * HWTH_HTTP_REQUEST_POST   1
   * HWTH_HTTP_REQUEST_GET    2
   * HWTH_HTTP_REQUEST_PUT    3
   * HWTH_HTTP_REQUEST_DELETE 4
   * HWTH_HTTP_REQUEST_HEAD   5
   */
  switch(apiMethodInt) {
  case 1:
   return "HWTH_HTTP_REQUEST_POST";
  case 2:
   return "HWTH_HTTP_REQUEST_GET";
  case 3:
   return "HWTH_HTTP_REQUEST_PUT";
  case 4:
   return "HWTH_HTTP_REQUEST_DELETE";
  case 5:
   return "HWTH_HTTP_REQUEST_HEAD";
  default:
   printf("ERROR: HTTP Method '%i' not recognized\n", apiMethodInt);
   return "UNRECOGNIZED";
  }
 } /* end function */


 /******************************************************
  * Function: setOptionFailed()
  *
  * If an HWTHSET failed to set an option for the input
  * handle, then surface diagnostics about the failure
  * and release any toolkit resources which may be
  * associated with the (now-useless) handle.
  ******************************************************/
 _Bool setOptionFailed( HWTH_RETURNCODE_TYPE *rcPtr,
                        HWTH_DIAGAREA_TYPE   *diagAreaPtr,
                        char *what,
                  HWTH_HANDLE_TYPE *handlePtr ) {

  if ( *rcPtr == HWTH_OK )
   return false;

  printDiag( rcPtr, diagAreaPtr, what );

  cleanupHandle( *handlePtr );

  return true;
  } /* end function */
/*
//BIND.SYSLIB DD DISP=SHR,DSN=CEE.SCEELKEX
//            DD DISP=SHR,DSN=CEE.SCEELKED
//            DD DISP=SHR,DSN=CEE.SCEECPP
//            DD DISP=SHR,DSN=SYS1.CSSLIB
