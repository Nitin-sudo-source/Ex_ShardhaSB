public with sharing class Ex_RentExcallationController {
    public Ex_RentExcallationController() {
        
    }
    

    @AuraEnabled(cacheable=true)
    public static Term_Sheet__c getTermSheet(Id termSheetID){
        try {
            Term_Sheet__c termSheet = [SELECT Id, Name, Start_Date__c, End_Date__c
                                       FROM Term_Sheet__c
                                       WHERE Id = :termSheetID];
            return termSheet;
        } catch (Exception e) {
            throw new CustomException('Error occurred while retrieving Term sheet with specified ID : ' + termSheetID);
        }
    }

    @AuraEnabled
    public static string createEscallationRecords(List<Escalation__c> escalltionList, String tremSheetId, string propertyType){
        Integer startingHeap = Limits.getHeapSize();
        System.debug('startingHeap : ' + startingHeap);

        List<Escalation__c> escalltionListToInsert = new List<Escalation__c>();
        System.debug(' escalltionList '+escalltionList);
        System.debug(' tremSheetId '+ tremSheetId);
        System.debug(' propertyType '+ propertyType);

        Set<String> escallationHashes = getEscallationRecordsHash(tremSheetId);
        
        try{
            List<Term_Sheet__c> termSheet = [ Select id, Name, Society__c FROM Term_Sheet__c Where Id=: tremSheetId ];

            Ex_RentExcallationControllerBatch rentEscalationBatch = new Ex_RentExcallationControllerBatch(
                                                                            escalltionList,
                                                                            tremSheetId,
                                                                            propertyType,
                                                                            termSheet[0].Society__c
                                                                        );
            Database.executeBatch(rentEscalationBatch, 200);

            /*
            if(termSheet != null && termSheet.size() >0 && termSheet[0].Society__c != null){
                List<Account> tenantList = [Select id, Name, Rent_Amount__c, Society__c,Configuration__c, Property_Type__c FROM Account
                where RecordType.Name ='Tenant Account' AND Society__c =:termSheet[0].Society__c ];
                System.debug(' tenantList ' + tenantList);
                
              for(Account tenant : tenantList){
                    
                    for(Escalation__c es : escalltionList){

                        Date startDate = es.Start_Date__c;
                        Date endDate = es.End_Date__c;
                        String tenantID = tenant.Id;

                        String currentEscalationHash = getHash(startDate, endDate, tenantID);
                        if(escallationHashes.contains(currentEscalationHash)){
                            System.debug('Exisiting esclation found');
                            continue;
                        }

                        Escalation__c escalltion = new Escalation__c();
                        if(es.Start_Date__c != null)
                        escalltion.Start_Date__c = es.Start_Date__c;
                        if(es.End_Date__c != null)
                        escalltion.End_Date__c = es.End_Date__c;
                        if(es.Months__c != null)
                        escalltion.Months__c = es.Months__c;
                        if(es.Escalation__c != null)
                        escalltion.Escalation__c = es.Escalation__c;
                        if(es.Term_Sheet__c != null)
                        escalltion.Term_Sheet__c = es.Term_Sheet__c;
                        if(tenant.Society__c != null)
                        escalltion.Society__c = tenant.Society__c;
                        escalltion.Tenant__c = tenant.Id;
                        if(propertyType != null && propertyType != ''){
                            escalltion.Property_Type__c = propertyType;
                        }

                        // Updated Rent Amount
                        if(tenant.Rent_Amount__c != null && es.Escalation__c != null){
                            escalltion.Updated_Rent_Amount__c = tenant.Rent_Amount__c + (tenant.Rent_Amount__c*es.Escalation__c/100);
                        }

                         if(tenant.Configuration__c == null|| String.IsBlank(tenant.Configuration__c)  || tenant.Property_Type__c==null || String.IsBlank(Tenant.Property_Type__c)){
                            string msg = tenant.Name + ' does not have a maintained Configuration or Property Type ';
                            return msg;
                         }
                        
                        if(es.Configuration__c != null && es.Configuration__c.contains(tenant.Configuration__c) && tenant.Property_Type__c.equalsIgnoreCase(propertyType) ){
                             escalltion.Configuration__c = es.Configuration__c;
                            escalltionListToInsert.add(escalltion);
                        }
                          
                    }
                }
                system.debug('escalltionListToInsert'+escalltionListToInsert);
                if(escalltionListToInsert != null && escalltionListToInsert.size()>0)
                    insert escalltionListToInsert;
                
            }
            */
            
        }catch (exception e){
            return e.getMessage();
        }

        Integer endingHeap = Limits.getHeapSize();
        System.debug('startingHeap : ' + endingHeap);
        System.debug('endingHeap - startingHeap : ' + (endingHeap - startingHeap));

        return 'success';
    }


    // Create a set of Hashes for each Escalation, easy to compare two records
    public static Set<String> getEscallationRecordsHash(String termsSheetID){

        Set<String> escallationHashes = new Set<String>();
        List<Escalation__c> escallations = [SELECT Id, Name, Tenant__c, Start_Date__c, End_Date__c, Term_Sheet__c
                                            FROM Escalation__c
                                            WHERE Term_Sheet__c = :termsSheetID AND 
                                                Tenant__c != null AND
                                                Start_Date__c != null AND
                                                End_Date__c != null ];
        
        for (Escalation__c escallation : escallations) {
            String escallationHash = getHash(escallation.Start_Date__c, escallation.End_Date__c, escallation.Tenant__c);
            escallationHashes.add(escallationHash);
        }

        return escallationHashes;
    }

    // Generate as Unique value for Provided Data
    public static String getHash(Date startDate, Date endDate, String tenantId){
        
        String combinedInput = tenantId + startDate.format() + endDate.format();
        Blob inputBlob = Blob.valueOf(combinedInput);
        Blob hashBlob = Crypto.generateDigest('SHA-256', inputBlob);

        return EncodingUtil.convertToHex(hashBlob);
    }

    // ---- Custom Exception ----
    public class CustomException extends Exception {}

 
}