global abstract inherited sharing class GC_TDTM_Runnable_2 extends npsp.TDTM_Runnable {

    // Arguments set as instance variables
    protected List<SObject> newList, oldList;
    protected DmlWrapper dmlWrapper;
    protected Schema.DescribeSObjectResult objResult;

    // Lazy-load maps if required
    protected Map<Id,SObject> newMap {
        get {
            if(newMap == null && newList != null) {
                newMap = new Map<Id,SObject>(newList);
            }
            return newMap;
        } set;
    }
    protected Map<Id,SObject> oldMap {
        get {
            if(oldMap == null && oldList != null) {
                oldMap = new Map<Id,SObject>(oldList);
            }
            return oldMap;
        } set;
    }

    // Modify if required in preRun()
    protected Boolean createLogsBefore = true;
    protected Boolean createLogsAfter = false;
    protected Boolean logExceptionsInTrigger = false;

    // Override to set variables or carry out processing prior to logging and runTrigger() call
    protected virtual void preRun() {}

    // Core method called by NPSP - delegates to runTrigger
    global virtual override DmlWrapper run(List<SObject> newListSObject, List<SObject> oldListSObject, npsp.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // Set instance variables
        this.newList = newListSObject;
        this.oldList = oldListSObject;
        this.objResult = objResult;
        this.dmlWrapper = new DmlWrapper();

        this.preRun();

        // Log state before trigger is run
        if(createLogsBefore) {
            try {
                GcND_TDTM_Util.logTrigger(className, newListSObject, oldListSObject, triggerAction);
            } catch(Exception e) {
                System.debug('Error logging before trigger: '+e.getMessage());
            }
        }

        // Call implementation
        try {
            switch on triggerAction {
                when BeforeInsert {
                    ((GC_TDTM.BeforeInsert) this).beforeInsert();
                }
                when AfterInsert {
                    ((GC_TDTM.AfterInsert) this).afterInsert();
                }
                when BeforeUpdate {
                    ((GC_TDTM.BeforeUpdate) this).beforeUpdate();
                }
                when AfterUpdate {
                    ((GC_TDTM.AfterUpdate) this).afterUpdate();
                }
                when BeforeDelete {
                    ((GC_TDTM.BeforeDelete) this).beforeDelete();
                }
                when AfterDelete {
                    ((GC_TDTM.AfterDelete) this).afterDelete();
                }
                when AfterUndelete {
                    ((GC_TDTM.AfterUndelete) this).afterUndelete();
                }
            }

        } catch(Exception e) {

            // If logging enabled, write error context to logs
            if(logExceptionsInTrigger) {
                String message = 'Error during trigger ' + triggerAction + ': ' + e.getMessage();
                GcLO_Logger.write('GC_TDTM', System.LoggingLevel.ERROR, 'Trigger Framework - Exception', message);
            }

            // Rethrow exception
            throw e;
        }

        // Log state after trigger runs
        if(createLogsAfter) {
            try {
                GcND_TDTM_Util.logTrigger(className, newListSObject, oldListSObject, triggerAction);
            } catch(Exception e) {
                System.debug('Error logging after trigger: '+e.getMessage());
            }
        }

        return dmlWrapper;
    }

    // Dynamically construct class name from object
    private String className {
        get {
            if(className == null) {
                className = String.valueOf(this).split(':')[0];
            }
            return className;
        } set;
    }


    // Return a TriggerHandler
    public virtual GcND_TDTM_Util.TriggerHandler getTriggerHandler(){
        GcND_TDTM_Util.TriggerHandler handler = new GcND_TDTM_Util.TriggerHandler();

        handler.Active =        this.handlerIsActive();
        handler.ClassName =     this.handlerClassName();
        handler.LoadOrder =     this.handlerLoadOrder();
        handler.ObjectName =    this.handlerObjectName();
        handler.TriggerAction = this.handlerTriggerAction();
        handler.Asynchronous =  this.handlerAsynchronous();
        handler.UserManaged =   this.handlerUserManaged();

        return handler;
    }

    // handlerLoadOrder() and handlerObjectName() must be implemented
    global abstract Integer handlerLoadOrder();
    global abstract String  handlerObjectName();

    // Other handler return methods are overrideable as needed
    protected virtual Boolean  handlerIsActive()  { return true; }
    protected virtual String   handlerClassName() { return className; }
    protected virtual Boolean  handlerAsynchronous()  { return false; }
    protected virtual Boolean  handlerUserManaged()  { return true; }

    protected virtual String handlerTriggerAction() {
        List<String> taStringList = new List<String>();

        if(this instanceof GC_TDTM.BeforeInsert) {
            taStringList.add('BeforeInsert');
        }
        if(this instanceof GC_TDTM.AfterInsert) {
            taStringList.add('AfterInsert');
        }
        if(this instanceof GC_TDTM.BeforeUpdate) {
            taStringList.add('BeforeUpdate');
        }
        if(this instanceof GC_TDTM.AfterUpdate) {
            taStringList.add('AfterUpdate');
        }
        if(this instanceof GC_TDTM.BeforeDelete) {
            taStringList.add('BeforeDelete');
        }
        if(this instanceof GC_TDTM.AfterDelete) {
            taStringList.add('AfterDelete');
        }
        if(this instanceof GC_TDTM.AfterUndelete) {
            taStringList.add('AfterUndelete');
        }
        
        String taStringConcat = String.join(taStringList, ';');

        return taStringConcat;
    }
}