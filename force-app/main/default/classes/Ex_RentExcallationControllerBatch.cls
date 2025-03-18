public class Ex_RentExcallationControllerBatch implements Database.Batchable<SObject>{
    
    List<Escalation__c> escalations;
    String termSheetID;
    String propertyType;
    String societyID;


    // Constructor : Store the required details to insert the records
    public Ex_RentExcallationControllerBatch(List<Escalation__c> escalations,
                                             String termSheetID,
                                             String propertyType,
                                             String societyID){
        this.escalations = escalations;
        this.termSheetID = termSheetID;
        this.propertyType = propertyType;
        this.societyID = societyID;

    }


    // Returns all the Tenant Accounts under that Society (for which escalations
    // need to be created)
    public Database.QueryLocator start(Database.BatchableContext batchableContext){

        String TENANT_ACCOUNT_RECORD_TYPE_NAME = 'Tenant Account';
        String SOCIETY_ID = this.societyID;
        String PROPERTY_TYPE = this.propertyType;

        return Database.getQueryLocator([
            SELECT Id, Name, Rent_Amount__c, Society__c,Configuration__c, Property_Type__c 
            FROM Account
            WHERE RecordType.Name = :TENANT_ACCOUNT_RECORD_TYPE_NAME AND
                  Society__c = :SOCIETY_ID AND
                  Property_Type__c = :PROPERTY_TYPE
        ]);
    }


    public void execute(Database.BatchableContext batchableContext, List<Account> tenantAccounts){

        try {
        
            // Collect Tenant Account IDs
            Set<Id> tenantAccountIDs = new Set<Id>();
            for (Account tenantAccount : tenantAccounts) {
                tenantAccountIDs.add(tenantAccount.Id);
            }

            /* 
            * Gathers the hashes of existing escalation records 
            * ( Each hash is combination of fields on escaltion record : Start_Date + End_Date + Tenant
            * which uniquely indentifies escalation record, allowing to avoid duplicate insertions )
            */
            Set<String> existingEscalationHashes = getEscallationRecordsHash(tenantAccountIDs, this.termSheetID);


            // Create the Escalations for provided accounts
            List<Escalation__c> escalationsToInsert = new List<Escalation__c>();
            for (Account tenantAccount : tenantAccounts) {
                
                for (Escalation__c escalationData : this.escalations) {
                    
                    // Skip the escalation creation based on required 'Escalation Configurations' 
                    // and 'Tenant Configuration'
                    String tenantConfiguration =  tenantAccount.Configuration__c;
                    String tenantPropertyType =  tenantAccount.Property_Type__c;
                    if(escalationData.Configuration__c != null && (
                        !escalationData.Configuration__c.contains(tenantConfiguration) ||
                        this.propertyType != tenantPropertyType
                    )){
                        System.debug('Ignored as doesn\'t matches required configuration');
                        continue;
                    }


                    // Skip record insertion if esclation with same infomation already exists
                    Date startDate = escalationData.Start_Date__c;
                    Date endDate = escalationData.End_Date__c;
                    String tenantID = tenantAccount.Id;

                    String currentEscalationHash = getHash(startDate, endDate, tenantID);
                    if(existingEscalationHashes.contains(currentEscalationHash)){
                        System.debug('Exisiting esclation found');
                        continue;
                    }


                    // Create Escalation record if escalation found \
                    Escalation__c escalation = new Escalation__c();
                    
                    if(escalationData.Start_Date__c != null){
                        escalation.Start_Date__c = escalationData.Start_Date__c;
                    }
                    if(escalationData.End_Date__c != null){
                        escalation.End_Date__c = escalationData.End_Date__c;
                    }
                    if(escalationData.Months__c != null){
                        escalation.Months__c = escalationData.Months__c;
                    }
                    if(escalationData.Escalation__c != null){
                        escalation.Escalation__c = escalationData.Escalation__c;
                    }
                    if(escalationData.Term_Sheet__c != null){
                        escalation.Term_Sheet__c = escalationData.Term_Sheet__c;
                    }

                    escalation.Society__c = this.societyID;
                    escalation.Tenant__c = tenantAccount.Id;
                    escalation.Property_Type__c = this.propertyType;
                    escalation.Configuration__c = escalationData.Configuration__c;

                    // Updated Rent Amount
                    if(tenantAccount.Rent_Amount__c != null && escalationData.Escalation__c != null){
                        escalation.Updated_Rent_Amount__c = tenantAccount.Rent_Amount__c + (tenantAccount.Rent_Amount__c*escalationData.Escalation__c/100);
                    }

                    escalationsToInsert.add(escalation);
                }
            }

            INSERT escalationsToInsert;

        } catch (Exception e) {
            System.debug('Internal Error Occurred while creating the Escalation records !' + e);
        }
    }


    public void finish(Database.BatchableContext batchableContext){
        System.debug('Rent Escallation Batch Executed Sucessfully !');
    }


    // Create a set of Hashes for each Escalation, easy to compare two records
    public static Set<String> getEscallationRecordsHash(Set<Id> tenantAccountIDs, Id termsSheetID){ 

        Set<String> escallationHashes = new Set<String>();
        List<Escalation__c> escallations = [SELECT Id, Name, Tenant__c, Start_Date__c, End_Date__c, Term_Sheet__c
                                            FROM Escalation__c
                                            WHERE Term_Sheet__c = :termsSheetID AND 
                                                  Tenant__c IN :tenantAccountIDs AND
                                                  Start_Date__c != null AND
                                                  End_Date__c != null ];
        
        for (Escalation__c escallation : escallations) {
            String escallationHash = getHash(escallation.Start_Date__c, escallation.End_Date__c, escallation.Tenant__c);
            escallationHashes.add(escallationHash);
        }

        System.debug('getEscallationRecordsHash -> currentHeapSize : ' + Limits.getHeapSize());


        return escallationHashes;
    }


    // Generate as Unique value for Provided Data
    public static String getHash(Date startDate, Date endDate, String tenantId){
    
        String combinedInput = tenantId + startDate.format() + endDate.format();
        Blob inputBlob = Blob.valueOf(combinedInput);
        Blob hashBlob = Crypto.generateDigest('SHA-256', inputBlob);

        return EncodingUtil.convertToHex(hashBlob);
    }
    
}