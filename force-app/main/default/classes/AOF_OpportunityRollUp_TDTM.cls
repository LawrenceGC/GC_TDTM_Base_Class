global without sharing class AOF_OpportunityRollUp_TDTM extends npsp.TDTM_Runnable {
    private List<Area_Of_Focus__c> newList, oldList;
    private Map<Id, Area_Of_Focus__c> oldMap, newMap;

    /*******************************************************************************************************
    * @param newListSObject the list of records from trigger new
    * @param oldListSObject the list of records from trigger old
    * @param triggerAction the trigger event that kicked off the process
    * @param objResult the object describe for the record that kicked off the process
    * @return dmlWrapper
    ********************************************************************************************************/
    global override DmlWrapper run(List<SObject> newListSObject, List<SObject> oldListSObject, npsp.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        DmlWrapper dmlWrapper = new DmlWrapper();
        GcND_TDTM_Util.logTrigger('AOF_Opportunity_RollUp_TDTM', newListSObject, oldListSObject, triggerAction);

        this.convertToAreaOfFocus(newListSObject, oldListSObject);

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

    // @description Area of Focus SObject to relevant object for trigger handler
    private void convertToAreaOfFocus(List<SObject> newListSObject, List<SObject> oldListSObject){
        // Populate newList & newMap
        if(newListSObject != null) {
            this.newList = new List<Area_Of_Focus__c>();
            this.newMap = new Map<Id, Area_Of_Focus__c>();
            for (SObject record : newListSObject) {
                this.newList.add((Area_Of_Focus__c) record);

                if (record.get('Id') != null) {
                    this.newMap.put((Id) record.get('Id'), (Area_Of_Focus__c) record);
                }
            }
        }

        // Populate oldList & oldMap
        if(oldListSObject != null) {
            this.oldList = new List<Area_Of_Focus__c>();
            this.oldMap = new Map<Id, Area_Of_Focus__c>();
            for (SObject record : oldListSObject) {
                this.oldList.add((Area_Of_Focus__c) record);

                if (record.get('Id') != null) {
                    this.oldMap.put((Id) record.get('Id'), (Area_Of_Focus__c) record);
                }
            }
        }
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