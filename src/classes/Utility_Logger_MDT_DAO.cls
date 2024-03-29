/**
 * Created by gtandeciarz on 7/30/18.
 */

public with sharing class Utility_Logger_MDT_DAO {
    @TestVisible
    static private List<Utility_Logger_Setting__mdt> customMetadataRecords = new List<Utility_Logger_Setting__mdt>();

    public static List<Utility_Logger_Setting__mdt> getCustomMetadataRecords() {

        if(customMetadataRecords.isEmpty()){
            Map<String, SObjectField> fields = Schema.SObjectType.Utility_Logger_Setting__mdt.fields.getMap();
            String SOQL = 'SELECT ';
            Integer ct = 0;
            for(SObjectField fld : fields.values()){
                if(fld.getDescribe().isCustom()){
                    if(ct>0){
                        SOQL += ', ';
                    }
                    SOQL += fld.getDescribe().getName();
                    ct ++;
                }
            }
            SOQL += ' FROM Utility_Logger_Setting__mdt ORDER BY Id DESC';
            customMetadataRecords = Database.query(SOQL);
        }
        return customMetadataRecords;
    }
}