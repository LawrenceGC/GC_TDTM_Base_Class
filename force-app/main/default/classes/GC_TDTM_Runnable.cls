public abstract inherited sharing class GC_TDTM_Runnable extends npsp.TDTM_Runnable {

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

    // Override in implementing classes
    public abstract DMLWrapper runTrigger(List<SObject> newListSObject, List<SObject> oldListSObject, npsp.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult);

    // Core method called by NPSP - delegates to runTrigger
    public virtual override DmlWrapper run(List<SObject> newListSObject, List<SObject> oldListSObject, npsp.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

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
            
            dmlWrapper = this.runTrigger(newListSObject, oldListSObject, triggerAction, objResult);

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

}