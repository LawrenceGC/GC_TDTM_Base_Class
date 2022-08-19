/**
 * @description       : TDTM Utility Class
 * @author            : Koen Wesselman <koen.wesselman@giveclarity.org>
 * @last modified on  : 12-08-2021
 * @last modified by  : Koen Wesselman <koen.wesselman@giveclarity.org>
 * Modifications Log 
 * Ver   Date         Author                                            Modification
 * 1.0   20-05-2021   Koen Wesselman <koen.wesselman@giveclarity.org>   Initial Version
**/
public with sharing class GcND_TDTM_Util {
    public class GcND_TDTM_UtilException extends Exception {}

//    private final static List<GcND_TDTM_Util.TriggerHandler> triggerHandlers = new List<GcND_TDTM_Util.TriggerHandler>{
//        ANY_GRFPledgesRollUp_TDTM.getTriggerHandlerAccount(),
//        ANY_GRFPledgesRollUp_TDTM.getTriggerHandlerOpportunity(),
//        ANY_GRFPledgesRollUp_TDTM.getTriggerHandlerPledgeRole(),
//        AOF_OpportunityRollUp_TDTM.getTriggerHandler()
//    };

    private final static String namespace;

    public final static List<GcND_TDTM_Util.TriggerHandler> triggerHandlers {
        get {
            if(triggerHandlers == null) {

                // Get all classes which immplement a GC_TDTM interface
                // Using GROUP BY on ApexTypeImplementor gives Internal Salesforce Error so we need to de-dupe afterwards!
                List<ApexTypeImplementor> interfaceImpls = [
                    SELECT ClassName
                    FROM ApexTypeImplementor 
                    WHERE InterfaceName IN (
                        'GC_TDTM.BeforeInsert',
                        'GC_TDTM.AfterInsert',
                        'GC_TDTM.BeforeUpdate',
                        'GC_TDTM.AfterUpdate',
                        'GC_TDTM.BeforeDelete',
                        'GC_TDTM.AfterDelete',
                        'GC_TDTM.AfterUndelete')
                    AND IsConcrete=true
                    AND ClassNamespacePrefix = :namespace];
                
                // Add class name to set so we don't have duplicates
                Set<String> handlerNamesSet = new Set<String>();
                for(ApexTypeImplementor ati : interfaceImpls) {
                    handlerNamesSet.add(ati.ClassName);
                }

                // Get the representation of the trigger handler SObject for each TDTM handler
                triggerHandlers = new List<GcND_TDTM_Util.TriggerHandler>();
                for(String handlerName : handlerNamesSet) {
                    GC_TDTM_Runnable_2 tdtm = (GC_TDTM_Runnable_2) Type.forName(namespace, handlerName).newInstance();
                    triggerHandlers.add(tdtm.getTriggerHandler());
                }
            }

            return triggerHandlers;
        } set;
    }

    /**
    * @description Inserts TDTM Trigger Handlers for managed Apex Classes for which no TDTM Trigger Handler exists yet
    * @return void
    **/
    public static void insertNewTDTMTriggerHandlers(){
        List<npsp__Trigger_Handler__c> triggerHandlersToInsert = new List<npsp__Trigger_Handler__c>();

        Set<String> existingTriggerHandlerClasses = new Set<String>();
        List<npsp__Trigger_Handler__c> existingTriggerHandlers = [SELECT npsp__Class__c, npsp__Object__c FROM npsp__Trigger_Handler__c LIMIT 10000];
        for(npsp__Trigger_Handler__c existingTriggerHandler : existingTriggerHandlers){
            existingTriggerHandlerClasses.add(
                existingTriggerHandler.npsp__Class__c + existingTriggerHandler.npsp__Object__c
            );
        }

        for(GcND_TDTM_Util.TriggerHandler triggerHandler : GcND_TDTM_Util.triggerHandlers){
            if(!existingTriggerHandlerClasses.contains(triggerHandler.className + triggerHandler.objectName)){
                npsp__Trigger_Handler__c th = GcND_TDTM_Util.createTriggerHandlerRecord(triggerHandler);
                triggerHandlersToInsert.add(th);
            }
        }

        if(triggerHandlersToInsert.size() > 0){
            insert triggerHandlersToInsert;
        }
    }

    /**
    * @description Resets all TDTM Trigger Handlers for managed Apex Classes
    * @return void
    **/
    public static void resetTDTMTriggerHandlers(){
        Set<String> existingTriggerHandlerClasses = new Set<String>();
        for(GcND_TDTM_Util.TriggerHandler triggerHandler : GcND_TDTM_Util.triggerHandlers){
            existingTriggerHandlerClasses.add(triggerHandler.className);
        }

        List<npsp__Trigger_Handler__c> existingTriggerHandlers = [SELECT Id FROM npsp__Trigger_Handler__c WHERE npsp__Class__c IN :existingTriggerHandlerClasses];
        delete existingTriggerHandlers;

        GcND_TDTM_Util.insertNewTDTMTriggerHandlers();
    }

    /**
    * @description Adds all TDTM Trigger Handlers specified in this class to the NPSP Trigger Handler cache
    * @return void
    **/
    public static void addTDTMTriggerHandlersToCache(){
        GcND_TDTM_Util.triggerHandlers.sort();

        for(GcND_TDTM_Util.TriggerHandler triggerHandler : GcND_TDTM_Util.triggerHandlers){
            GcND_TDTM_Util.addTDTMTriggerHandlerToCache(triggerHandler);
        }
    }
 
    /**
    * @description Adds a specific TDTM Trigger Handler to the NPSP Trigger Handler cache
    * @return void
    **/
    public static void addTDTMTriggerHandlerToCache(GcND_TDTM_Util.TriggerHandler triggerHandler){
        npsp__Trigger_Handler__c th = GcND_TDTM_Util.createTriggerHandlerRecord(triggerHandler);

        List<npsp__Trigger_Handler__c> listHandlers = npsp.TDTM_Config_API.getCachedRecords();
        listHandlers.add(th); 
    }

    private static npsp__Trigger_Handler__c createTriggerHandlerRecord(GcND_TDTM_Util.TriggerHandler triggerHandler){
        if(triggerHandler == null){
            throw new GcND_TDTM_UtilException('A Trigger Handler instance is required');
        } else if(triggerHandler.className == null){
            throw new GcND_TDTM_UtilException('The className attribute on the Trigger Handler instance must be populated');
        } else if(Type.forName(triggerHandler.className) == null){
            throw new GcND_TDTM_UtilException('The className attribute on the Trigger Handler instance must be an existing Apex Class');
        } else if(triggerHandler.objectName == null){
            throw new GcND_TDTM_UtilException('The objectName attribute on the Trigger Handler instance must be populated');
        }

        npsp__Trigger_Handler__c th = new npsp__Trigger_Handler__c();
        th.npsp__Asynchronous__c = (triggerHandler.asynchronous != null) ? triggerHandler.asynchronous : false;
        th.npsp__Class__c = triggerHandler.className;
        th.npsp__Load_Order__c = triggerHandler.loadOrder;
        th.npsp__Object__c = triggerHandler.objectName;
        th.npsp__Active__c = triggerHandler.active;
        th.npsp__Trigger_Action__c = triggerHandler.triggerAction;
        th.npsp__User_Managed__c = triggerHandler.userManaged;
        return th; 
    }

    /**
    * @description Disables the NPSP Customisable Rollup Triggers for this execution 
    **/
    public static void disableNPSPCustomisableRollupTriggers(){
        List<npsp__Trigger_Handler__c> handlers = npsp.TDTM_Config_API.getCachedRecords();
        for (npsp__Trigger_Handler__c th : handlers) {
            if (th.npsp__Class__c == 'CRLP_Rollup_TDTM') {
                th.npsp__Active__c = false;
            }
        }
    }

    /**
    * @description Logs details about a Trigger firing
    * @return void
    **/
    public static void logTrigger(String tdtmTrigger, List<SObject> newListSObject, List<SObject> oldListSObject, npsp.TDTM_Runnable.Action triggerAction){
        String logMessage = 'Trigger Action: ' + triggerAction + '\r\n\r\n';
        logMessage += 'Old SObjects: ' + oldListSObject + '\r\n\r\n';
        logMessage += 'New SObjects: ' + newListSObject;

        GcLO_Logger.write('gcnd', System.LoggingLevel.DEBUG, tdtmTrigger, logMessage);
    }

    /**
    * @description Adds data in a TDTM_Handler_Data instance to the DmlWrapper. Used when performing insert/update/delete operations from a single handler method.
    * @return npsp.TDTM_Runnable.DmlWrapper
    **/
    public static npsp.TDTM_Runnable.DmlWrapper addDataToDmlWrapper(npsp.TDTM_Runnable.DmlWrapper dmlWrapper, TDTM_Handler_Data data){
        if(data != null){
            if(data.objectsToInsert != null){
                dmlWrapper.objectsToInsert.addAll(data.objectsToInsert);
            }

            if(data.objectsToUpdate != null){
                dmlWrapper.objectsToUpdate.addAll(data.objectsToUpdate);
            }

            if(data.objectsToDelete != null){
                dmlWrapper.objectsToDelete.addAll(data.objectsToDelete);
            }
        }
        return dmlWrapper;
    }

    /** INNER CLASS FOR TDTM TRIGGER HANDLER DETAILS **/
    public class TriggerHandler implements Comparable {
        public Boolean asynchronous;
        public String className;
        public Integer loadOrder;
        public String objectName;
        public Boolean active;
        public String triggerAction;
        public Boolean userManaged;

        public TriggerHandler(){}

        public Integer compareTo(Object compareTo){
            GcND_TDTM_Util.TriggerHandler compareToTH = (GcND_TDTM_Util.TriggerHandler) compareTo;

            Integer returnValue = 0;
            if(this.loadOrder > compareToTH.loadOrder){
                returnValue = 1;
            } else if(this.loadOrder < compareToTH.loadOrder){
                returnValue = -1;
            }

            return returnValue;
        }
    }

    /** INNER CLASS FOR HANDLING INSERT, UPDATES & DELETES FROM THE SAME TRIGGER HANDLER METHOD **/
    public class TDTM_Handler_Data {
        public List<SObject> objectsToInsert;
        public List<SObject> objectsToUpdate;
        public List<SObject> objectsToDelete;
        public TDTM_Handler_Data(){ }
    }
}