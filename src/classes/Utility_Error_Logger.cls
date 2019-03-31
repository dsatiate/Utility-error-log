/**
 * Created  on 6/21/18.
 */

global class Utility_Error_Logger {

    @TestVisible
    static final String DEFAULT_CUSTOM_PERMISSION_API_NAME = 'Utility_Logging_Enabled';

    global static void Log(String msg){
        Log(new Utility_LogRecord(msg));
    }

    global static void Log(List<String> messages){
        List<Utility_LogRecord> recs = new List<Utility_LogRecord>();
        for(String msg : messages){
            recs.add(new Utility_LogRecord(msg));
        }
        Log(recs);
    }

    global static void Log(System.Exception ex){
        Log(new List<Exception>{ex});
    }

    public static void Log(Utility_LogRecord rec){
        Log(new List<Utility_LogRecord>{rec});
    }

    global static void Log(List<Exception> exceptions){
        List<Utility_LogRecord> recs = new List<Utility_LogRecord>();
        for(Exception ex : exceptions){
            recs.add(new Utility_LogRecord(ex));
        }
        Log(recs);
    }

    public static void Log(List<Utility_LogRecord> records){
        records.sort();
        List<String> logsAsJSON = new List<String>();
        for(Utility_LogRecord rec : records){
            if(!String.isEmpty(rec.message)){
                System.debug(rec.message);
                logsAsJSON.add(JSON.serialize(rec));
            }
        }
        sendToServices(logsAsJSON);
    }

    global static void processSaveResults(List<Database.SaveResult> srList){
        for(Database.SaveResult sr : srList){
            if (sr.isSuccess()) {
                System.debug('Successfully published error log event: ' + sr.getId());
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' +
                            err.getStatusCode() +
                            ' - ' +
                            err.getMessage());
                }
            }
        }
    }

    public static Map<String, Utility_Logger_Service> servicesMap {
        get {
            if(servicesCache == null){
                servicesCache = new Map<String, Utility_Logger_Service>();
                for(Utility_Logger_Setting__mdt mdt : Utility_Logger_MDT_DAO.getCustomMetadataRecords()){
                    servicesCache.put(mdt.Custom_Logger_Class__c, getServiceInstance(mdt));
                }
            }
            return servicesCache;
        }
    }

    @TestVisible
    static Map<String, Utility_Logger_Service> servicesCache {get;set;}

    @TestVisible
    static void sendToServices(List<String> logs){
        try{
            for(Utility_Logger_Service svc : servicesMap.values()){
                if(svc != null && svc.settingsMDT.Enabled__c && checkPermissionsForService(svc.settingsMDT)){
                    svc.processRecords( logs );
                }
            }
        } catch (Exception ex){
            System.debug(ex.getMessage());
        }
    }

    @TestVisible
    static Boolean checkPermissionsForService(Utility_Logger_Setting__mdt mdt){
        Boolean useCustomPermissions = mdt.Use_Custom_Permissions__c;
        String customPermissionName = String.isNotEmpty( mdt.Custom_Permission_API_Name__c ) ?
                mdt.Custom_Permission_API_Name__c : mdt.Custom_Permission_API_Name__c;

        return useCustomPermissions ?
                Test.isRunningTest() ? hasPermissions : FeatureManagement.checkPermission(customPermissionName) : true; //default to affirmative
    }

    @TestVisible
    static Boolean hasPermissions { get {
        Map<Id,CustomPermission> customPermissionNamesById = new Map<Id, CustomPermission>( [SELECT Id, DeveloperName
                FROM CustomPermission WHERE DeveloperName=: DEFAULT_CUSTOM_PERMISSION_API_NAME] );

        List<SetupEntityAccess> setupEntities =
        [SELECT SetupEntityId
                FROM SetupEntityAccess
                WHERE SetupEntityId IN :customPermissionNamesById.keySet() AND
                        ParentId IN (SELECT PermissionSetId
                                FROM PermissionSetAssignment
                                WHERE AssigneeId = :UserInfo.getUserId())];
        return setupEntities.size() > 0;
    } }

    @TestVisible
    static Utility_Logger_Service getServiceInstance(Utility_Logger_Setting__mdt mdt){
        Utility_Logger_Service svc;
        try {
            svc = (Utility_Logger_Service)Type.forName(mdt.Custom_Logger_Class__c).newInstance();
            svc.settingsMDT = mdt;
        } catch (Exception ex){
            System.debug(ex.getMessage());
        }
        return svc;
    }
}