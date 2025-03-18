public class Ex_TermSheetHandlerService {
    
    public static void TermSheetValidation(Set<Id> societyIds , List<Term_Sheet__c>termSheets){
        
        Map<Id,List<Term_Sheet__c>>termSheetWithSocities = getTermSheetswithSocity(societyIds);
        
        
      for(Term_Sheet__c newTR:termSheets){
          if(termSheetWithSocities != null && termSheetWithSocities.containsKey(newTR.Society__c)){
              List<Term_Sheet__c> existingTermSheet = termSheetWithSocities.get(newTR.Society__c);
              if(existingTermSheet != null){
                  for(Term_Sheet__c existingTr:existingTermSheet){
                      if((newTR.Start_Date__c != null && newTR.Start_Date__c >= existingTr.Start_Date__c && newTR.Start_Date__c <= existingTr.End_Date__c) ||
                         (newTR.End_Date__c != null && newTR.End_Date__c >= existingTr.Start_Date__c && newTR.End_Date__c <= existingTr.End_Date__c )){

                            String formattedStartDate = (existingTr.Start_Date__c.day() < 10 ? '0' + String.valueOf(existingTr.Start_Date__c.day()) : String.valueOf(existingTr.Start_Date__c.day())) + '-' +
                                                        (existingTr.Start_Date__c.month() < 10 ? '0' + String.valueOf(existingTr.Start_Date__c.month()) : String.valueOf(existingTr.Start_Date__c.month())) + '-' +
                                                        existingTr.Start_Date__c.year();
                            String formattedEndDate =  (existingTr.End_Date__c.day() < 10 ? '0' + String.valueOf(existingTr.End_Date__c.day()) : String.valueOf(existingTr.End_Date__c.day())) + '-' +
                                                       (existingTr.End_Date__c.month() < 10 ? '0' + String.valueOf(existingTr.End_Date__c.month()) : String.valueOf(existingTr.End_Date__c.month())) + '-' +
                                                        existingTr.End_Date__c.year();


                         newTR.addError('Term Sheet dates are overlapping with existing termsheet ' + existingTr.Name + ' ' +
                                         ' where Start Date : ' + formattedStartDate +
                                         ' & End Date : '+  formattedEndDate);
                      }
                  }
              }
          }
          if(newTR.End_Date__c!= null && newTR.Start_Date__c != null && newTR.Start_Date__c >newTR.End_Date__c){
              newTR.addError('End Date should be greater than Start Date');
          }
      }
    }
    
    public static Map<Id,List<Term_Sheet__c>> getTermSheetswithSocity(Set<Id> societyIds){
        Map<Id,List<Term_Sheet__c>> termSheetswithSocity= new Map<Id,List<Term_Sheet__c>>();
        
        List<Term_Sheet__c> termSheetList = [Select Id , Name , Start_Date__c, End_Date__c, Society__c,  Society__r.Name
                                             From Term_Sheet__c 
                                             where Society__c IN: societyIds AND Society__c != null AND Start_Date__c != null AND End_Date__c != null];
        for(Term_Sheet__c ts:termSheetList){
            if(!termSheetswithSocity.containsKey(ts.Society__c))
                termSheetswithSocity.put(ts.Society__c,New List<Term_Sheet__c>{ts});
              else{
                 termSheetswithSocity.get(ts.Society__c).add(ts);   
                }
        }
        
        if(termSheetswithSocity!= null && termSheetswithSocity.size()>0)
            return termSheetswithSocity;
        else 
            return null;
        
    }

}