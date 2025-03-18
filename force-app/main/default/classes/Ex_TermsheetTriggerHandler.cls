public class Ex_TermsheetTriggerHandler {
    
    public static void beforeInsert(List<Term_Sheet__c>termSheetList){
       Set<Id> societyIds = new Set<Id>();
        for(Term_Sheet__c termSheet :termSheetList ){
            if(termSheet.Society__c != null && termSheet.Start_Date__c != null && termSheet.End_Date__c != null )
                societyIds.add(termSheet.Society__c);
               
        }
        
        if(societyIds !=null && societyIds.size()>0)
          Ex_TermSheetHandlerService.TermSheetValidation(societyIds,termSheetList);
        
    }

}