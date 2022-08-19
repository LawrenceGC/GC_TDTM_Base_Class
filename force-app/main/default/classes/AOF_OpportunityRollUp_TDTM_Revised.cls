global without sharing class AOF_OpportunityRollUp_TDTM_Revised extends GC_TDTM_Runnable {
    
    /*******************************************************************************************************
    * @param newListSObject the list of records from trigger new
    * @param oldListSObject the list of records from trigger old
    * @param triggerAction the trigger event that kicked off the process
    * @param objResult the object describe for the record that kicked off the process
    * @return dmlWrapper
    ********************************************************************************************************/
    global override DmlWrapper runTrigger(List<SObject> newListSObject, List<SObject> oldListSObject, npsp.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        if(triggerAction == npsp.TDTM_Runnable.Action.AfterInsert){
            dmlWrapper.objectsToUpdate.addAll(AreaOfFocusTriggerHandler.rollUpAreasOfFocusToOpportunity(newList));
        } else if(triggerAction == npsp.TDTM_Runnable.Action.AfterUpdate){
            dmlWrapper.objectsToUpdate.addAll(AreaOfFocusTriggerHandler.rollUpAreasOfFocusToOpportunity(newList));
        } else if(triggerAction == npsp.TDTM_Runnable.Action.AfterDelete){
            dmlWrapper.objectsToUpdate.addAll(AreaOfFocusTriggerHandler.rollUpAreasOfFocusToOpportunity(oldList));
        } else if(triggerAction == npsp.TDTM_Runnable.Action.AfterUndelete){
            dmlWrapper.objectsToUpdate.addAll(AreaOfFocusTriggerHandler.rollUpAreasOfFocusToOpportunity(newList));
        }

        return dmlWrapper;
    }

    // @description Return a TriggerHandler for the GcND_TDTM_Util class
    public static GcND_TDTM_Util.TriggerHandler getTriggerHandler(){
        GcND_TDTM_Util.TriggerHandler triggerHandler = new GcND_TDTM_Util.TriggerHandler();
        triggerHandler.asynchronous = false;
        triggerHandler.className = 'AOF_OpportunityRollUp_TDTM';
        triggerHandler.loadOrder = 1;
        triggerHandler.objectName = 'Area_Of_Focus__c';
        triggerHandler.active = true;
        triggerHandler.triggerAction = 'AfterInsert;AfterUpdate;AfterDelete;AfterUndelete';
        triggerHandler.userManaged = true;
        return triggerHandler;
    }
}