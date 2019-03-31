/**
 * Created by gtandeciarz on 9/17/18.
 */

global abstract class Utility_Logger_Service {
    public Utility_Logger_Setting__mdt settingsMDT {get; set;}
    global abstract void processRecords(List<String> recordsAsJSON);
}