trigger Ex_TermSheetTrigger on Term_Sheet__c (before insert) {

    if(Trigger.isBefore && Trigger.isInsert){
        Ex_TermsheetTriggerHandler.beforeInsert(trigger.new);
    }
}