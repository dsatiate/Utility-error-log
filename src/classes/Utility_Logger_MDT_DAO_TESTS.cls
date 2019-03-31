/**
 * Created by gtandeciarz on 7/30/18.
 */

@IsTest
private class Utility_Logger_MDT_DAO_TESTS {
    static testMethod void testGetMetadata() {
        List<Utility_Logger_Setting__mdt> customMetadataRecords;
        Test.startTest();
        customMetadataRecords = Utility_Logger_MDT_DAO.getCustomMetadataRecords();
        Test.stopTest();
        System.assertEquals( [ SELECT Id FROM Utility_Logger_Setting__mdt ].size(), customMetadataRecords.size(), 'Size should match' );
    }
}