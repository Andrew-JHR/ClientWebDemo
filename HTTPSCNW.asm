//ANDREWJA JOB  CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//STEP1    EXEC ASMACLG ,
//*   PARM.C='OBJECT,NODECK,XREF(SHORT),PC(ON,GEN,MC,MS)'
//SYSIN    DD   *
**********************************************************************
* Test Client Web Enablement Toolkit Assembler APIs
* Andrew Jan  5/May/2023
**********************************************************************
         PRINT NOGEN
*------------------------------------------------*
*
         PRINT OFF
         LCLA  &REG
.LOOP    ANOP                              GENERATE REGS.
R&REG    EQU   &REG
&REG     SETA  &REG+1
         AIF   (&REG LE 15).LOOP
         PRINT ON
*
*
         HWTHIASM ,     http enabler
*
WORKAREA DSECT  ,
*
PLIST          DS    7F

RETCODE        DS    F
HNDLTYPE       DS    F
CONNHNDLE      DS    3F
REQHNDLE       DS    3F
DIAGAREA       DS    CL136

OPTION         DS    F
OPTIONVALADDR  DS    F
OPTIONVALLEN   DS    F
SLIST          DS    F

OPTVAL         DS    F

FROMWHICH      DS    CL16

RESPBODY       DS    CL256

SAVREGRSP      DS    18F

WORKLEN        EQU   *-WORKAREA
*
*------------------------------------------------*
*
HTTPSCNW CSECT
HTTPSCNW AMODE 31
         USING *,R15              setup addressibility
         STM   R14,R12,12(R13)    use r13 as base as well as
         LR    R2,R13             reg-save area
         B     CMNTTAIL           skip over the remarks
*
CMNTHEAD EQU   *
         PRINT GEN                print out remarks
         DC    CL8'&SYSDATE'      compiling date
         DC    C' '
         DC    CL5'&SYSTIME'      compiling time
         DC    C'ANDREW JAN'      author
         CNOP  2,4                ensure half word boundary
         PRINT NOGEN              disable macro expansion
CMNTTAIL EQU   *

         BALR  R12,0
         BAL   R13,76(R12)

         DROP  R15                avoid compiling warning

SAVREG   DS    18F
         USING SAVREG,R13
         ST    R2,4(R13)
         ST    R13,8(R2)
*
*---MAINSTREAM------------------------------------*
*
*
        BAL    R6,GET_PARM          get the argument
*
        BAL    R6,OPEN_FILES        open the output file
*
        BAL    R6,GO_PROCESS        go process
*
FINISH  EQU    *
        BAL    R6,CLOSE_FILES       close the output file
*
        B      RETURN               back
*
*-------------------------------------------------------*
*
GET_PARM   EQU  *

         BR    R6

OPEN_FILES EQU  *
         OPEN  (OUTFILE,OUTPUT)
         BR    R6
*
*-------------------------------------------------------*
*
GO_PROCESS  EQU   *

         USING WORKAREA,R11         addressibility
         GETMAIN RC,LV=WORKLEN,BNDRY=PAGE,LOC=ANY
         LR    R11,R1

*
*--connection setup---------------------------------------------
*
*initiate to get a handle
         L     R2,=A(HWTH_HANDLETYPE_CONNECTION) set type as conn.
         ST    R2,HNDLTYPE          save it
         CALL  HWTHINIT,                                               X
               (RETCODE,            return code                        X
               HNDLTYPE,            handle type                        X
               CONNHNDLE,           handle                             X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         MVC   FROMWHICH,=CL16'#Inital Conntion' tag
         BNE   SHOW_ERROR           nonzero, errors occur

*set verbose
         L     R2,=A(HWTH_OPT_VERBOSE) set verbose
         ST    R2,OPTION            save it
         L     R2,=A(HWTH_VERBOSE_ON)  set verbose on
         ST    R2,OPTVAL            set verbose on
         LA    R2,OPTVAL
         ST    R2,OPTIONVALADDR
         LA    R2,4
         ST    R2,OPTIONVALLEN
         MVC   FROMWHICH,=CL16'#Set Verbose On ' tag
         BAL   R7,SET_CONN_OPT      go set the option

*set uri
         L     R2,=A(HWTH_OPT_URI)  set uri
         ST    R2,OPTION            save it
         LA    R2,URI               get the uri's addr
         ST    R2,OPTIONVALADDR     set it
         LA    R2,L'URI             uri's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Set connect URI' tag
         BAL   R7,SET_CONN_OPT      go set the option

*set port
         L     R2,=A(HWTH_OPT_PORT) set port number
         ST    R2,OPTION            save it
         LA    R2,PORT              get the port variable's addr
         ST    R2,OPTIONVALADDR     set it
         LA    R2,4                 port variable's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Set IP Port Val' tag
         BAL   R7,SET_CONN_OPT      go set the option

*set timeout
         L     R2,=A(HWTH_OPT_SNDTIMEOUTVAL) sent time out for send
         ST    R2,OPTION            save it
         LA    R2,TIMEOUT           get the timeout value
         ST    R2,OPTIONVALADDR     set it
         LA    R2,4                 port variable's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Set TimeOut Val' tag
         BAL   R7,SET_CONN_OPT      go set the option

         L     R2,=A(HWTH_OPT_RCVTIMEOUTVAL) sent time out for receive
         ST    R2,OPTION            save it
         LA    R2,TIMEOUT           get the timeout value
         ST    R2,OPTIONVALADDR     set it
         LA    R2,4                 port variable's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Set TimeOut Val' tag
         BAL   R7,SET_CONN_OPT      go set the option

*set to use ssl
         L     R2,=A(HWTH_OPT_USE_SSL) ssl option
         ST    R2,OPTION            save it
         L     R2,=A(HWTH_SSL_USE)  choose to set ssl on our own
         ST    R2,OPTVAL            save the value
         LA    R2,OPTVAL            get the address of the value
         ST    R2,OPTIONVALADDR     set it
         LA    R2,4                 port variable's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Set to Use SSL ' tag
         BAL   R7,SET_CONN_OPT      go set the option

*set to use a SAF keyring
         L     R2,=A(HWTH_OPT_SSLKEYTYPE) want to set key type
         ST    R2,OPTION            save it
         L     R2,=A(HWTH_SSLKEYTYPE_KEYRINGNAME) use keyring
         ST    R2,OPTVAL            save the value
         LA    R2,OPTVAL            get the address of the value
         ST    R2,OPTIONVALADDR     set it
         LA    R2,4                 port variable's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Use SAF Keyring' tag
         BAL   R7,SET_CONN_OPT      go set the option

*set the keyring
         L     R2,=A(HWTH_OPT_SSLKEY) choose to set keyring
         ST    R2,OPTION            save it
         LA    R2,KEYRING           get the keyring name's address
         ST    R2,OPTIONVALADDR     set it
         LA    R2,L'KEYRING         keyring name's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Keyring Name   ' tag
         BAL   R7,SET_CONN_OPT      go set the option

*force to use tls 1.2
         L     R2,=A(HWTH_OPT_SSLVERSION) want to set ssl type
         ST    R2,OPTION            save it
         L     R2,=A(HWTH_SSLVERSION_TLSv12) use tls 1.2
         ST    R2,OPTVAL            save the value
         LA    R2,OPTVAL            get the address of the value
         ST    R2,OPTIONVALADDR     set it
         LA    R2,4                 port variable's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Use TLS 1.2    ' tag
         BAL   R7,SET_CONN_OPT      go set the option

         CALL  HWTHCONN,                                               X
               (RETCODE,            return code                        X
               CONNHNDLE,           handler                            X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         MVC   FROMWHICH,=CL16'#Exec Connection' tag
         BNE   SHOW_ERROR           nonzero, errors occur
*
*--request setup------------------------------------------------
*
*initiate to get a request handle
         L     R2,=A(HWTH_HANDLETYPE_HTTPREQUEST) set type as request
         ST    R2,HNDLTYPE          save it
         CALL  HWTHINIT,                                               X
               (RETCODE,            return code                        X
               HNDLTYPE,            handle type                        X
               REQHNDLE,            handle                             X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         MVC   FROMWHICH,=CL16'#Initial Request' tag
         BNE   SHOW_ERROR           nonzero, errors occur

*setup list of headers
         XR    R2,R2                zero
         ST    R2,SLIST             require when slist is new
         L     R2,=A(HWTH_SLST_NEW) slist function type
         ST    R2,OPTION            save it
         LA    R2,HEADTYPE          get the address of the value
         ST    R2,OPTIONVALADDR     header string's addr
         LA    R2,L'HEADTYPE        header string's length
         MVC   FROMWHICH,=CL16'#New Header List' tag
         ST    R2,OPTIONVALLEN      set it

         CALL  HWTHSLST,                                               X
               (RETCODE,            return code                        X
               REQHNDLE,            handle                             X
               OPTION,              slst type is new                   X
               SLIST,               slst                               X
               OPTIONVALADDR,       string address                     X
               OPTIONVALLEN,        string length                      X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         MVC   FROMWHICH,=CL16'#Set Header List' tag
         BNE   SHOW_ERROR           nonzero, errors occur

*set request method as post
         L     R2,=A(HWTH_OPT_REQUESTMETHOD) request method
         ST    R2,OPTION            save it
         L     R2,=A(HWTH_HTTP_REQUEST_POST) post
         ST    R2,OPTVAL            save the value
         LA    R2,OPTVAL            get the address of the value
         ST    R2,OPTIONVALADDR     set it
         LA    R2,4                 port variable's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Set as Post    ' tag
         BAL   R7,SET_REQ_OPT       go set the option

*set uri path
         L     R2,=A(HWTH_OPT_URI)  set uri path
         ST    R2,OPTION            save it
         LA    R2,PATH              get the address of path
         ST    R2,OPTIONVALADDR     set it
         LA    R2,L'PATH            port variable's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Set App Path   ' tag
         BAL   R7,SET_REQ_OPT       go set the option

*set header
         L     R2,=A(HWTH_OPT_HTTPHEADERS) set header
         ST    R2,OPTION            save it
         LA    R2,SLIST             get the address of path
         ST    R2,OPTIONVALADDR     set it
         LA    R2,4                 port variable's length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Set Data Type  ' tag
         BAL   R7,SET_REQ_OPT       go set the option

*translate outbound to ascii
         L     R2,=A(HWTH_OPT_TRANSLATE_REQBODY) convert code page
         ST    R2,OPTION            save it
         L     R2,=A(HWTH_XLATE_REQBODY_E2A) ebcdic to ascii
         ST    R2,OPTVAL            save it
         LA    R2,OPTVAL            address of the variable
         ST    R2,OPTIONVALADDR     save it
         LA    R2,4                 length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Translate Req. ' tag
         BAL   R7,SET_REQ_OPT       go set the option

*translate inbound to ascii
         L     R2,=A(HWTH_OPT_TRANSLATE_RESPBODY) convert code page
         ST    R2,OPTION            save it
         L     R2,=A(HWTH_XLATE_RESPBODY_A2E) ascii to ebcdic
         ST    R2,OPTVAL            save it
         LA    R2,OPTVAL            address of the variable
         ST    R2,OPTIONVALADDR     save it
         LA    R2,4                 length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Translate Resp.' tag
         BAL   R7,SET_REQ_OPT       go set the option

*link to data we want to send
         L     R2,=A(HWTH_OPT_REQUESTBODY) set the data to send
         ST    R2,OPTION            save it
         LA    R2,REQ               address of the request data
         ST    R2,OPTIONVALADDR     save it
         LA    R2,REQL              length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Translate Resp.' tag
         BAL   R7,SET_REQ_OPT       go set the option

*specify where to keep the response
         L     R2,=A(HWTH_OPT_RESPONSEBODY_USERDATA) response
         ST    R2,OPTION            save it
         LA    R2,RESPBODY          address of the response
         ST    R2,OPTIONVALADDR     save it
         LA    R2,L'RESPBODY        length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Where For Resp.' tag
         BAL   R7,SET_REQ_OPT       go set the option

*specify the program to receive the response

         LA    R2,=A(GETRESP)       get the resp callback
         ST    R2,OPTIONVALADDR     save it
         L     R2,=A(HWTH_OPT_RESPONSEBODY_EXIT) response exit
         ST    R2,OPTION            save it
         LA    R2,4                 length
         ST    R2,OPTIONVALLEN      set it
         MVC   FROMWHICH,=CL16'#Prog to Accept' tag
         BAL   R7,SET_REQ_OPT       go set the option

*send to request
         CALL  HWTHRQST,                                               X
               (RETCODE,            return code                        X
               CONNHNDLE,           connection handle                  X
               REQHNDLE,            request handle                     X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         MVC   FROMWHICH,=CL16'#Exec. the Send ' tag
         BNE   SHOW_ERROR           nonzero, errors occur

*free the request header
         L     R2,=A(HWTH_SLST_FREE) slist function type
         ST    R2,OPTION            save it
         XR    R2,R2                set as zero
         ST    R2,OPTIONVALADDR     should be zero for freeing
         ST    R2,OPTIONVALLEN      should be zero for freeing

         CALL  HWTHSLST,                                               X
               (RETCODE,            return code                        X
               REQHNDLE,            handle                             X
               OPTION,              slst type is new                   X
               SLIST,               slst                               X
               OPTIONVALADDR,       string address                     X
               OPTIONVALLEN,        string length                      X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         MVC   FROMWHICH,=CL16'#Free Header Lst' tag
         BNE   SHOW_ERROR           nonzero, errors occur

*reset the request for next use
         CALL  HWTHRSET,                                               X
               (RETCODE,            return code                        X
               REQHNDLE,            handle                             X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         MVC   FROMWHICH,=CL16'#Reset Request  ' tag
         BNE   SHOW_ERROR           nonzero, errors occur

*close the connection to server
         CALL  HWTHDISC,                                               X
               (RETCODE,            return code                        X
               CONNHNDLE,           handle                             X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         MVC   FROMWHICH,=CL16'#Close Connect. ' tag
         BNE   SHOW_ERROR           nonzero, errors occur

*free the work area associated with the request
         L     R2,=A(HWTH_NOFORCE)  set force option as nonforce
         ST    R2,OPTION            save it
         CALL  HWTHTERM,                                               X
               (RETCODE,            return code                        X
               REQHNDLE,            handle                             X
               OPTION,              handle                             X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         MVC   FROMWHICH,=CL16'#Terminate Req. ' tag
         BNE   SHOW_ERROR           nonzero, errors occur

*free the work area associated with the connection
         CALL  HWTHTERM,                                               X
               (RETCODE,            return code                        X
               CONNHNDLE,           handle                             X
               OPTION,              handle                             X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         MVC   FROMWHICH,=CL16'#Teminate Conn. ' tag
         BNE   SHOW_ERROR           nonzero, errors occur

         FREEMAIN RC,LV=WORKLEN,A=(R11)

         BR    R6
*
*-------------------------------------------------*
*

*
*-------------------------------------------------*
*

SET_CONN_OPT   EQU  *
         CALL  HWTHSET,                                                X
               (RETCODE,            return code                        X
               CONNHNDLE,           handler                            X
               OPTION,              option name                        X
               OPTIONVALADDR,       option value address               X
               OPTIONVALLEN,        option value length                X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         BNE   SHOW_ERROR           nonzero, errors occur

         BR    R7                  go back

*
*---------------------------------------------------*
*

SET_REQ_OPT    EQU  *
         CALL  HWTHSET,                                                X
               (RETCODE,            return code                        X
               REQHNDLE,            handler                            X
               OPTION,              option name                        X
               OPTIONVALADDR,       option value address               X
               OPTIONVALLEN,        option value length                X
               DIAGAREA),           diagnostic area                    X
               VL,MF=(E,PLIST)
         ICM   R15,B'1111',RETCODE  check the return code
         BNE   SHOW_ERROR           nonzero, errors occur

         BR    R7                   go back

*
*---------------------------------------------------*
*

SHOW_ERROR     EQU  *
         PUT   OUTFILE,FROMWHICH   print out the step in trouble
         PUT   OUTFILE,RETCODE     print out the return code
         PUT   OUTFILE,DIAGAREA    print out the return code
         B     FINISH              go stop the process

*
*--------------------------------------------------------*
*
CLOSE_FILES EQU  *
         CLOSE  OUTFILE            close files
         BR    R6
*
*--------------------------------------------------------*
*
RETURN   EQU   *
         L     R13,4(R13)
         ST    R15,16(,R13)        save the return code
         LM    R14,R12,12(R13)     restore registers
         L     R14,12(,R13)        load return address
         BR    R14                 go back to caller
*
*--------------------------------------------------------*
*
GETRESP  DC    0D'0'               align on doubleword
         DROP  R13                 finished with R13
         STM   R14,R12,12(R13)     save the regs to caller's savearea
         LR    R2,R13              keep in r2
         BASR  R15,0               set base reg
         USING *,R15               use r15 as the base
         LA    R13,SAVREGRSP       our reg savearea
         ST    R13,8(,R2)          save ours to caller's savearea
         ST    R2,4(,R13)          save caller's r13 to our savearea
         LR    R13,R2              keep our savearea on r13
         DROP  R15                 reset base
         BASR  R12,0               set base reg again
         USING *,R12               use r12 as the base

         USING HWTH_RBDYEXITPARMLIST,R4
*HWTH_RBDYEXITPARMLIST          DSECT
*HWTH_RBDYEXITHHTTPSTATUSPTR    DS A  Address of Status Line struct
*HWTH_RBDYEXITEXITFLAGSPTR      DS A  Address of exitFlags
*HWTH_RBDYEXITRESPBODYPTRPTR    DS A  Address of respBodyPtr
*HWTH_RBDYEXITRESPBODYLENPTR    DS A  Address of respBodyLen
*HWTH_RBDYEXITUSERDATAPTRPTR    DS A  Address of bodyUserDataPtr
*HWTH_RBDYEXITUSERDATALENPTR    DS A  Address of bodyerUserDataLen
*
         LR    R4,R1            copy parm addr.
         L     R4,HWTH_RBDYEXITRESPBODYPTRPTR respbody respbody ptr
         L     R2,0(R4)         addr. of response data
         PUT   OUTFILE,0(R2)    print the response data

         L     R13,4(,R13)      restore caller's r13
         LM    R14,R12,12(R13)  return
         BR    R14
*
*--------------------------------------------------------*
*

         LTORG

TIMEOUT  DC    F'10'
PORT     DC    F'3000'
URI      DC    C'https://10.1.1.1'
PATH     DC    C'/api/data/'
KEYRING  DC    C'CLNTWEB'
REQ      DC    C'{"name": "Mainframe zOS Assembler", "age": 59, '
         DC    C'"email": "mainframe.zos@ibm.com", '
         DC    C'"address": {"street": "123 Main St", '
         DC    C'"city": "Taipei", "state": "Taiwan", '
         DC    C'"zip": "1964"}}'
REQL     EQU   *-REQ
HEADTYPE DC    C'Content-type: application/json'
*
*--------------------------------------------------------*
*
*
OUTFILE  DCB DSORG=PS,DDNAME=SYSPRINT,MACRF=PM,LRECL=134
*
         END
/*
//L.SYSLIB   DD  DISP=SHR,DSN=SYS1.CSSLIB
//G.SYSPRINT DD  SYSOUT=*
//*.SYSABEND DD  SYSOUT=*
//*
