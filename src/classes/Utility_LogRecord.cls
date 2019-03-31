/**
 * Created by gtandeciarz on 7/10/18.
 */

public virtual class Utility_LogRecord implements Comparable{
    public String message {get;set;}
    public String className {get;set;}
    public String otherDetails {get;set;}
    public String stacktrace {get;set;}
    public Datetime logDate {get;set;}
    String userIDString {get;private set;}
    public String runningUserID { get{
        if(String.isEmpty(userIDString)){
            userIDString = UserInfo.getUserId();
        }
        return userIDString;
    } set {
        userIDString = value;
    }}

    public Utility_LogRecord(Exception ex){
        setVars(ex.getMessage(),null,getOtherDetailsExceptionTypeString(ex),ex.getStackTraceString(),null);
    }

    public Utility_LogRecord(String msg){
        setVars(msg,null,null,null,null);
    }

    public Utility_LogRecord(Exception ex, String className, String otherDetails){
        String details  = String.isEmpty(otherDetails) ? getOtherDetailsExceptionTypeString(ex) : otherDetails;
        setVars(ex.getMessage(),className, details, ex.getStackTraceString(), null);
    }

    public Utility_LogRecord(String msg, String className, String otherDetails){
        setVars(msg,className,otherDetails,null,null);
    }

    @TestVisible
    static String getOtherDetailsExceptionTypeString(Exception ex){
        return 'Exception Type: ' + ex.getTypeName();
    }

    @TestVisible
    void setVars(String msg, String className, String otherDetails, String stackTrace, Datetime dt){
        this.message = msg;
        this.className = className;
        this.otherDetails = otherDetails;
        this.stacktrace = stackTrace;
        this.logDate = dt == null ? System.now() : dt;
    }

    public Utility_Error_Log__c getSObject(){
        Utility_Error_Log__c log = new Utility_Error_Log__c();
        log.Error_Message__c = this.message;
        log.Class_Name__c = this.className;
        log.Other_Details__c = this.otherDetails;
        log.StackTraceString__c = this.stacktrace;
        log.Log_Date_Time__c = this.logDate;
        log.Running_User__c = this.runningUserID;
        return log;
    }

    public Utility_Error_Log_PE__e getPlatformEventObject(){
        Utility_Error_Log_PE__e log = new Utility_Error_Log_PE__e();
        log.Error_Message__c = this.message;
        log.Class_Name__c = this.className;
        log.Other_Details__c = this.otherDetails;
        log.StackTraceString__c = this.stacktrace;
        log.Log_Date_Time__c = this.logDate;
        log.Running_User_ID__c = this.runningUserID;
        return log;
    }

    public Integer compareTo( Object objToCompare ) {
        Utility_LogRecord obj2 = (Utility_LogRecord)objToCompare;
        if(logDate > obj2.logDate) return 1;
        if(logDate < obj2.logDate) return -1;
        return 0;
    }
}