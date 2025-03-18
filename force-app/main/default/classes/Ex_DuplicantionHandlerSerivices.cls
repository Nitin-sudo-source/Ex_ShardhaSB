public class Ex_DuplicantionHandlerSerivices {
    
    
    public static void TenantDuplicationCheck(Set<String>unitNames , List<Account>newAccounts){
        Map<String,List<Account>> exisitingAccWithUnit = getAccWithTenants(unitNames);
        
        for(Account acc:newAccounts){
            if(exisitingAccWithUnit != null && exisitingAccWithUnit.containsKey(acc.Existing_Unit__c)){
                List<Account> exisitingAccList = exisitingAccWithUnit.get(acc.Existing_Unit__c);
                for(Account existingAcc :exisitingAccList){
                    if(acc.Existing_Unit__c != null && acc.Society__c != null && acc.Tower__c != null ){
                        if(acc.Existing_Unit__c == existingAcc.Existing_Unit__c && acc.Tower__c == existingAcc.Tower__c  && acc.Society__c == existingAcc.Society__c ){
                            acc.addError('Tenant is already exist with unit '+ existingAcc.Existing_Unit__c + ' aginst Tower '+ existingAcc.Tower__r.Name + ' and socity '+ existingAcc.Society__r.Name);
                        }
                    }
                }
            }
        }
        
    }
    
    public static Map<String,List<Account>>getAccWithTenants(Set<String>unitNames){
        Map<String,List<Account>> exisitingAccWithUnit = new Map<String,List<Account>>();
        
        List<Account>exisitingAccList = new List<Account>();
        exisitingAccList = [select Id ,Name , Existing_Unit__c , Society__c, Tower__c,Tower__r.Name, Society__r.Name From Account Where Existing_Unit__c IN:unitNames AND Society__c!= null AND Tower__c != null];
        
         for(Account acc:exisitingAccList){
            if(!exisitingAccWithUnit.containsKey(acc.Existing_Unit__c))
                exisitingAccWithUnit.put(acc.Existing_Unit__c,New List<Account>{acc});
              else{
                 exisitingAccWithUnit.get(acc.Existing_Unit__c).add(acc);   
                }
        }
        if(exisitingAccWithUnit!= null && exisitingAccWithUnit.size()>0)
        return exisitingAccWithUnit;
        else 
            return null;
    }
    

}