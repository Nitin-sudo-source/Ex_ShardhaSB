trigger Ex_AccountTrigger on Account (before insert, before update, after insert) {

    switch on Trigger.OPERATIONTYPE {
        when BEFORE_INSERT {
            Ex_AccountTriggerHandler.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            Ex_AccountTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap, Trigger.new);
        }
        when AFTER_INSERT {
            Ex_AccountTriggerHandler.afterInsert(Trigger.new);
        }
    }
}