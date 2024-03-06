//ANDREWJC JOB  IBM,SP,CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID,REGION=0M  
//STEP1    EXEC PGM=BPXBATSL                                        
//SYSPRINT DD   SYSOUT=*                                            
//SYSOUT   DD   SYSOUT=*                                            
//STDOUT   DD   SYSOUT=*                                            
//STDERR   DD   SYSOUT=*                                            
//STDPARM  DD   *                                                   
SH javac -encoding IBM-937 -cp /u/andrewj httpsClnt.java                              
/*                                                                  
//
//*
//* in /etc/profile 
//* PATH=$PATH:/usr/lpp/java/J8.0_64/bin
//* export PATH                         
//*