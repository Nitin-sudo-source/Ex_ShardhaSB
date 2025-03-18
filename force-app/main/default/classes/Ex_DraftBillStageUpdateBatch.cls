public class Ex_DraftBillStageUpdateBatch implements Database.Batchable<sObject>, schedulable {
    
    public Database.queryLocator start(Database.BatchableContext bc){
        string query = 'SELECT Id, Name , Bill_Date__c,Amount__c, Charge_Name__c, Tenant__c, Term_Sheet__c, Bill_Stage__c, Due_Date__c '+
                       'FROM Bill__c Where Tenant__c !=null AND Bill_Date__c !=null AND Bill_Stage__c = \'Draft\' AND Amount__c !=null';
            
            return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc , List<Bill__c> draftBills){
        system.debug('draftBills '+draftBills);
        for(Bill__c db :draftBills){
            if(db.Bill_Date__c <= System.Today()){
                db.Bill_Stage__c = 'Actual';
            }
        }
        if(draftBills!=null  && draftBills.size()>0)
        Database.update(draftBills);
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
    
    public void execute(schedulableContext sc){
        Ex_DraftBillStageUpdateBatch dbStageUpdate = new Ex_DraftBillStageUpdateBatch();
        Database.executeBatch(dbStageUpdate,50);
    }
}