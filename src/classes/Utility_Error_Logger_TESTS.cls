/**
 * Created  on 6/21/18.
 */

@IsTest
private class Utility_Error_Logger_TESTS {

    static final String PE_SERVICE_API_NAME = 'Utility_Logger_Service_PE';

    @IsTest
    static void testEventLogger() {
        enableLogging();
        Test.startTest();
        Utility_Error_Logger.Log(new CustomException('manually generated exception message'));
        Test.stopTest();
        List<Utility_Error_Log__c> logs = [SELECT Id, Error_Message__c FROM Utility_Error_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('manually generated exception message', logs[0].Error_Message__c);
    }

    @IsTest
    static void testEventLoggerNoPermissionSet() {
        removeLoggingPermissionSet();
        setService(true);
        System.debug(JSON.serializePretty(Utility_Error_Logger.servicesMap.values()));
        Test.startTest();
        Utility_Error_Logger.Log(new CustomException('manually generated exception message'));
        Test.stopTest();
        assertNoRecords();
    }

    @IsTest
    static void testCheckPermissionsForService(){
        removeLoggingPermissionSet();
        Utility_Logger_Setting__mdt mdt = getMDTFromJSON(true);
        System.assert(Utility_Error_Logger.checkPermissionsForService(mdt) == false);
    }

    @IsTest
    static void testEventLoggerEmptyMessage() {
        enableLogging();
        Test.startTest();
        Utility_Error_Logger.Log('');
        Test.stopTest();
        assertNoRecords();
    }

    @IsTest
    static void testGetSettingsMap() {
        List<Utility_Logger_Setting__mdt> settings = [SELECT Id FROM Utility_Logger_Setting__mdt];
        System.assertEquals(settings.size(), Utility_Error_Logger.servicesMap.size());
    }

    @IsTest
    static void processSaveResultsFail(){
        Utility_Error_Log__c log = new Utility_Error_Log__c();
        Utility_Error_Logger.processSaveResults(Database.insert(new List<Utility_Error_Log__c>{log},false));
        assertNoRecords();
    }

    @IsTest
    static void testSendToServicesFail() {
        enableLogging();
        Test.startTest();
        Utility_Error_Logger.sendToServices(new List<String>{'bad data'});
        Test.stopTest();
        assertNoRecords();
    }

    @IsTest
    static void testGetService() {
        Utility_Logger_Setting__mdt mdt = [SELECT Id, Custom_Logger_Class__c FROM Utility_Logger_Setting__mdt
        WHERE Custom_Logger_Class__c =: PE_SERVICE_API_NAME];
        System.assert(Utility_Error_Logger.getServiceInstance(mdt) != null);
    }

    @IsTest
    static void testGetServiceFail() {
        Utility_Logger_Setting__mdt badMDT = new Utility_Logger_Setting__mdt();
        System.assert(Utility_Error_Logger.getServiceInstance(badMDT) == null);
    }

    @IsTest
    static void testUtilityLoggerSObjectMethod() {
        Utility_LogRecord rec = new Utility_LogRecord('error message');
        Test.startTest();
        Utility_Error_Log__c recObj = rec.getSObject();
        Test.stopTest();
        System.assert(recObj.Error_Message__c.equals(rec.message));
        System.assert(recObj.Log_Date_Time__c != null);
    }

    @IsTest
    static void testEventLoggerMultipleLogRecords() {
        enableLogging();
        Test.startTest();
        List<String> messages = new List<String>{'err1', 'err2', 'err3'};
        Utility_Error_Logger.Log(messages);
        Test.stopTest();
        List<Utility_Error_Log__c> logs = [SELECT Id, Error_Message__c FROM Utility_Error_Log__c];
        System.assertEquals(3, logs.size(),'There should be 3 error logs saved');
    }

    @IsTest
    static void testLogRecordSorting(){
        Utility_LogRecord rec1 = new Utility_LogRecord('should be last');
        Utility_LogRecord rec2 = new Utility_LogRecord('rec2');
        Utility_LogRecord rec3 = new Utility_LogRecord('should be first');
        rec1.logDate = rec1.logDate.addDays(3);
        rec3.logDate = rec3.logDate.addDays(-1);
        List<Utility_LogRecord> recs = new List<Utility_LogRecord>{rec1,rec2,rec3};
        recs.sort();
        System.assertEquals(recs[0],rec3);
        System.assertEquals(recs[2],rec1);
    }

    @IsTest
    static void testLogRecordConstructors(){
        String className = Utility_Error_Logger_TESTS.class.getName();
        Utility_LogRecord rec1 = new Utility_LogRecord('should be last');
        Utility_LogRecord rec2 = new Utility_LogRecord('rec2', className, 'testing string message');
        Utility_LogRecord rec3 = new Utility_LogRecord(new CustomException('test exception'));
        Utility_LogRecord rec4 = new Utility_LogRecord(new CustomException('test exception'),className,'testing custom exception');
        List<Utility_LogRecord> recs = new List<Utility_LogRecord>{rec1,rec2,rec3,rec4};
        //message
        System.assert(String.isNotEmpty(rec1.message));
        System.assert(String.isNotEmpty(rec2.message));
        System.assert(String.isNotEmpty(rec3.message));
        System.assert(String.isNotEmpty(rec4.message));
        //classname
        System.assert(String.isEmpty(rec1.className));
        System.assert(String.isNotEmpty(rec2.className));
        System.assert(String.isEmpty(rec3.className));
        System.assert(String.isNotEmpty(rec4.className));
        //other details
        System.assert(String.isEmpty(rec1.otherDetails));
        System.assert(String.isNotEmpty(rec2.otherDetails));
        System.assert(String.isNotEmpty(rec3.otherDetails));
        System.assert(String.isNotEmpty(rec4.otherDetails));
        //stacktrace
        System.assert(String.isEmpty(rec1.stacktrace));
        System.assert(String.isEmpty(rec2.stacktrace));
        System.assert(String.isNotEmpty(rec3.stacktrace));
        System.assert(String.isNotEmpty(rec4.stacktrace));

        System.debug(rec3.stacktrace);
        //exception type defaults
        System.assertEquals(rec3.otherDetails,
                Utility_LogRecord.getOtherDetailsExceptionTypeString(new CustomException('t')));
    }

    static void assertNoRecords(){
        List<Utility_Error_Log__c> logs = [SELECT Id, Error_Message__c FROM Utility_Error_Log__c];
        System.assertEquals(0, logs.size(), 'No error logs should exist');
    }

    static void enableLogging(){
        assignLoggingPermission();
        setService(true);
    }

    static void setService(Boolean enabled){
        Utility_Logger_Setting__mdt mdt = getMDTFromJSON(enabled);
        Utility_Logger_Service svc = Utility_Error_Logger.getServiceInstance(mdt);
        Utility_Error_Logger.servicesCache = new Map<String, Utility_Logger_Service>();
        Utility_Error_Logger.servicesMap.put(PE_SERVICE_API_NAME, svc);
    }

    static String getNamespacePrefix(){
        ApexClass cs =[SELECT NamespacePrefix FROM ApexClass WHERE Name =:'Utility_Error_Logger'];
        String nameSpacePrefix= cs.NamespacePrefix;
        String prefix = '';
        if(String.isNotEmpty(nameSpacePrefix)){
            prefix = nameSpacePrefix +'__';
        }
        return prefix;
    }

    static Utility_Logger_Setting__mdt getMDTFromJSON(Boolean enabled){
        String enabledString = enabled ? 'true' : 'false';
        Map<String, SObjectField> fields = Schema.SObjectType.Utility_Logger_Setting__mdt.fields.getMap();
        JSONGenerator jq = JSON.createGenerator(true);
        jq.writeStartObject();
        for(Utility_Logger_Setting__mdt m : Utility_Logger_MDT_DAO.getCustomMetadataRecords()){
            if(m.Custom_Logger_Class__c.equalsIgnoreCase(PE_SERVICE_API_NAME)){
                for(SObjectField fld : fields.values()){
                    if(fld.getDescribe().isCustom()){
                        jq.writeFieldName(fld.getDescribe().getName());
                        String val = m.get(fld.getDescribe().getName()).toString();
                        if(fld.getDescribe().getName().endsWithIgnoreCase('enabled__c')){
                            val = enabledString;
                        }
                        jq.writeString(val);
                    }
                }
            }
        }
        jq.writeEndObject();
        System.debug('*********** jq.getAsString():\n');
        System.debug(jq.getAsString());
        Utility_Logger_Setting__mdt mdt = (Utility_Logger_Setting__mdt)JSON.deserialize(jq.getAsString(), Utility_Logger_Setting__mdt.class);
        System.debug('*********** deserialized JSON:\n');
        System.debug(mdt);
        return mdt;
    }

    static void assignLoggingPermission(){
        // Create PermissionSet with Custom Permission and assign to test user
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test_Logging_Custom_Permission';
        ps.Label = 'Test';
        insert ps;
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [SELECT Id FROM CustomPermission
                WHERE DeveloperName =: Utility_Error_Logger.DEFAULT_CUSTOM_PERMISSION_API_NAME][0].Id;
        insert sea;
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;

        System.assert(Utility_Error_Logger.hasPermissions);
    }

    static void removeLoggingPermissionSet(){
        List<PermissionSetAssignment> psa = [SELECT Id FROM PermissionSetAssignment
                WHERE AssigneeId=: UserInfo.getUserId()
                        AND PermissionSetId IN (SELECT Id FROM PermissionSet WHERE Name = 'Utility_Error_Logger')];
        delete psa;
        psa = [SELECT Id FROM PermissionSetAssignment
                WHERE AssigneeId=: UserInfo.getUserId()
                        AND PermissionSetId IN (SELECT Id FROM PermissionSet WHERE Name = 'Utility_Error_Logger')];
        System.assertEquals(0,psa.size());
        System.assert(Utility_Error_Logger.hasPermissions == false);
    }

    class CustomException extends Exception { }
}