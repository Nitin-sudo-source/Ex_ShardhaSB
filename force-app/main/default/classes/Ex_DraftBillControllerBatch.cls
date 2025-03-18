global class Ex_DraftBillControllerBatch Implements Database.Batchable<sObject>, Database.Stateful {
    
    Private Id specificSocietyId;
    Private Id specifictermsheetId;
    Private Date specificstartDate;
    Private Date specificendDate;
    Private Map<String, Integer>specificThresholdMap;
    
    //createDraftBillsForTenent(tenants, startDate, endDate, ThresholdMap, termsheetId);
    public Ex_DraftBillControllerBatch(Id SocietyId,Id termsheetId, Date startDate, Date endDate, Map<String, Integer>ThresholdMap){
        this.specificSocietyId = SocietyId;
        this.specifictermsheetId = termsheetId; 
        this.specificstartDate = startDate;
        this.specificendDate = endDate;
        this.specificThresholdMap = ThresholdMap;
        
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        
        string query = 'SELECT Id, IsDeleted, MasterRecordId, Name, LastName, FirstName, Salutation, Type, RecordTypeId, ' +
               'AccountSource,  Society__c, Actual_Offered_Area__c, Final_Committed_Area__c, Rent_Frequency__c, ' +
               'Rent_Type__c,Rent_Eligibility__c, Rent_Amount__c, Rent_Payment_time__c, Rent_Specific_Date__c, Actual_Rent_paid__c, Expected_Number_Rent__c, ' +
               'Corpus_1_Eligibility__c, Corpus_1_Type__c, Corpus_1_Amount__c, Corpus_1_Payment_time__c, Corpus_1_Rate__c, ' +
               'Corpus_1_Specific_Date__c, Actual_Corpus_1_Paid__c, Corpus_1_Frequency__c, Corpus_2_Frequency__c, Corpus_2_Eligibility__c, ' +
               'Corpus_2_Type__c, Corpus_2_Amount__c, Corpus_2_Rate__c, Corpus_2_Payment_Time__c, Corpus_2_Specific_Date__c, Actual_Corpus_2_Paid__c, ' +
               'Corpus_3_Frequency__c, Corpus_3_Eligibility__c, Corpus_3_Type__c, Corpus_3_Amount__c, Corpus_3_Rate__c, Corpus_3_Payment_Time__c, ' +
               'Corpus_3_Specific_Date__c, Actual_Corpus_3_Paid__c, Corpus_4_Frequency__c, Corpus_4_Eligibility__c, Corpus_4_Type__c, ' +
               'Corpus_4_Amount__c, Corpus_4_Payment_Time__c, Corpus_4_Rate__c, Corpus_4_Specific_Date__c, Actual_Corpus_4_Paid__c, ' +
               'Corpus_5_Frequency__c, Corpus_5_Eligibility__c, Corpus_5_Type__c, Corpus_5_Amount__c, Corpus_5_Rate__c, Corpus_5_Payment_Time__c, ' +
               'Corpus_5_Specific_Date__c, Actual_Corpus_5_Paid__c, Transport_Rent_Frequency__c, Transport_Rent_Eligibility__c, ' +
               'Transport_Rent_Amount__c, Transport_Rent_Rate__c, Transport_Rent_Payment_time__c, Transport_Rent_Specific_Date__c, ' +
               'Transport_Rent_Type__c, Actual_Transport_Rent_Paid__c, Brokerage_Frequency__c, Brokerage_Type__c, Brokerage_Eligibility__c, ' +
               'Brokerage_Amount__c, Brokerage_Rate__c, Brokerage_Payment_Time__c, Brokerage_Specific_Date__c, Actual_Brokerage_Paid__c, ' +
               'MISC_Frequency__c, MISC_Eligibility__c, MISC_Type__c, MISC_Amount__c, MISC_Rate__c, MISC_Payment_Time__c, MISC_Specific_Date__c, ' +
               'Actual_MISC_Paid__c, Existing_Unit__c, Tenant_Carpet__c, Configuration__c, Rent_Rate__c ' +
               'FROM Account WHERE RecordType.Name = \'Tenant Account\' AND Society__c = :specificSocietyId';
            return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> tenants){
        
        System.debug('Executed !!!');
        Ex_DraftBillController.createDraftBillsForTenent(tenants, specificstartDate, specificendDate, specificThresholdMap, specifictermsheetId);
        System.debug('Executed !!!');
        
    }
    global void finish(Database.BatchableContext bc){

        try {
            Term_Sheet__c termsheet = [SELECT Id, Name, Last_Bill_Generated_Datetime__c
                                  FROM Term_Sheet__c
                                  WHERE Id = :this.specifictermsheetId];
            termsheet.Last_Bill_Generated_Datetime__c = System.now();
        } catch (Exception e) {
            System.debug('Internal Error occurred while updating termsheet : ' + e);
        }
        
        System.debug('Bill Created Successfully !');
    }

}