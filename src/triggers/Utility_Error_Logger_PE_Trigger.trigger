/**
 * Created by gtandeciarz on 6/28/18.
 */

trigger Utility_Error_Logger_PE_Trigger on Utility_Error_Log_PE__e (after insert) {
    //Convert the Platform Event Notifications into Error Log Records for saving into the database
    Utility_Logger_Service_PE.savePlatformEventsAsLogs(Trigger.new);
}