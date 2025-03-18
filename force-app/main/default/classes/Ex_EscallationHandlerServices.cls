public with sharing class Ex_EscallationHandlerServices {
    
    public static void validateEscalations(List<Escalation__c> escalations){

        // Get term sheet details for validation
        Set<Id> termSheetIds = new Set<Id>();
        for (Escalation__c escalation : escalations) { 
            termSheetIds.add(escalation.Term_Sheet__c);
        }
        Map<Id, Term_Sheet__c> termsSheetDetails = getTermsSheetDetails(termSheetIds);


        for (Escalation__c escalation : escalations) {
            Term_Sheet__c termSheet = termsSheetDetails.get(escalation.Id);

            if(escalation.Start_Date__c > escalation.End_Date__c){
                escalation.addError(' Escalation\'s End date should be greater than Start Date');
            }
            if (escalation.Start_Date__c < termSheet.Start_Date__c || escalation.Start_Date__c > termSheet.End_Date__c || 
                escalation.End_Date__c < termSheet.Start_Date__c || escalation.End_Date__c > termSheet.End_Date__c) {
                escalation.addError(' Escalation\'s Start/End Date must be in align with Termsheet\'s Start/End Date');
            }
        }
    }



    // Get term sheet details
    public static Map<Id, Term_Sheet__c> getTermsSheetDetails(Set<Id> termSheetIds){

        List<Term_Sheet__c> termSheets =  [SELECT Id, Name, Start_Date__c, End_Date__c
                                           FROM Term_Sheet__c
                                           WHERE Id IN :termSheetIds];

        Map<Id, Term_Sheet__c> termSheetDetails = new Map<Id, Term_Sheet__c>();
        for (Term_Sheet__c  termSheet : termSheets) {
            termSheetDetails.put(termSheet.Id, termSheet);
        }

        return termSheetDetails;
    }
}