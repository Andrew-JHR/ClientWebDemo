//ANDREWJJ JOB CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID           
//JAVA EXEC PROC=JVMPRC86,                                 
// JAVACLS='httpsClnt'                                     
//STDENV DD *                                              
# This is a shell script which configures                  
# any environment variables for the Java JVM.              
# Variables must be exported to be seen by the launcher.   
                                                           
. /etc/profile                                             
export JAVA_HOME=/usr/lpp/java/J8.0_64                     
                                                           
export PATH=/bin:"${JAVA_HOME}"/bin                        
                                                           
LIBPATH=/lib:/usr/lib:"${JAVA_HOME}"/bin                   
LIBPATH="$LIBPATH":"${JAVA_HOME}"/lib/s390x                
LIBPATH="$LIBPATH":"${JAVA_HOME}"/lib/s390x/j9vm           
LIBPATH="$LIBPATH":"${JAVA_HOME}"/bin/classic              
export LIBPATH="$LIBPATH":                                 
                                                                         
# Customize your CLASSPATH here                                          
# APP_HOME=$JAVA_HOME                                                    
APP_HOME=/u/andrewj                                                      
                                                                         
CLASSPATH=$APP_HOME:"${JAVA_HOME}"/lib:"${JAVA_HOME}"/lib/ext            
                                                                         
# Add Application required jars to end of CLASSPATH                      
for i in "${APP_HOME}"/*.jar; do                                         
    CLASSPATH="$CLASSPATH":"$i"                                          
    done                                                                 
export CLASSPATH="$CLASSPATH":                                           
                                                                         
# Set JZOS specific options                                              
# Use this variable to specify encoding for DD STDOUT and STDERR         
#export JZOS_OUTPUT_ENCODING=Cp1047                                      
# Use this variable to prevent JZOS from handling MVS operator commands  
#export JZOS_ENABLE_MVS_COMMANDS=false                                   
# Use this variable to supply additional arguments to main               
#export JZOS_MAIN_ARGS=""                                                
                                                                         
# Configure JVM options                                                  
IJO="-Xms16m -Xmx128m"                                                   
# Uncomment the following to aid in debugging "Class Not Found" problems 
#IJO="$IJO -verbose:class"                                               
# Uncomment the following if you want to run with Ascii file encoding..  
#IJO="$IJO -Dfile.encoding=ISO8859-1"                                    
export IBM_JAVA_OPTIONS="$IJO "                                          
/*                                                                       
//                                                                       