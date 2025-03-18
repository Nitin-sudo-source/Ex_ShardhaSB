trigger Ex_EscallationTrigger on Escalation__c (before insert) {

    if(Trigger.isBefore && Trigger.isInsert){
        // Ex_EscallationTriggerHandler.beforeInsert(Trigger.new);
    }
}