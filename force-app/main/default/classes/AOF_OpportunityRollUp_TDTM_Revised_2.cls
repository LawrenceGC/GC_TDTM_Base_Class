global without sharing class AOF_OpportunityRollUp_TDTM_Revised_2 extends GC_TDTM_Runnable_2 
    implements GC_TDTM.AfterInsert, GC_TDTM.AfterUpdate, GC_TDTM.AfterDelete, GC_TDTM.AfterUndelete {
    
    public void afterInsert() {
        dmlWrapper.objectsToUpdate.addAll(AreaOfFocusTriggerHandler.rollUpAreasOfFocusToOpportunity(newList));
    }
    public void afterUpdate() {
        dmlWrapper.objectsToUpdate.addAll(AreaOfFocusTriggerHandler.rollUpAreasOfFocusToOpportunity(newList));
    }
    public void afterDelete() {
        dmlWrapper.objectsToUpdate.addAll(AreaOfFocusTriggerHandler.rollUpAreasOfFocusToOpportunity(newList));
    }
    public void afterUndelete() {
        dmlWrapper.objectsToUpdate.addAll(AreaOfFocusTriggerHandler.rollUpAreasOfFocusToOpportunity(newList));
    }

    public override Integer handlerLoadOrder() { return 1; }
    public override String handlerObjectName() { return 'Area_Of_Focus__c'; }
    
}