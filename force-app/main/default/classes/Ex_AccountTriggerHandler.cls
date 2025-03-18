public class Ex_AccountTriggerHandler {
    
    public static void beforeInsert(List<account>newAccountList){
       Set<string> UnitNames = new Set<String>(); 
      
        for(Account acc : newAccountList){
            if(Schema.sObjectType.Account.getRecordTypeInfosbyId().get(acc.RecordTypeId).getName() == 'Tenant Account' && acc.Existing_Unit__c != null && !String.ISBlank(acc.Existing_Unit__c)
               && acc.Society__c != null && acc.Tower__c != null ){
                UnitNames.add(acc.Existing_Unit__c );
            }
        }
        System.debug('UnitNames before Insert '+UnitNames);
        if(unitNames != null && unitNames.size()>0){
            Ex_DuplicantionHandlerSerivices.TenantDuplicationCheck(unitNames,newAccountList);
        }
      }

     public static void beforeUpdate(Map<Id,Account>oldAccountMap , Map<Id,Account>newAccountMap,List<account>newAccountList ){
       Set<string> UnitNames = new Set<String>(); 
        
        for(Account newAccounts : newAccountMap.values()){
             Account oldAccounts = oldAccountMap.get(newAccounts.Id);
           
            if(Schema.sObjectType.Account.getRecordTypeInfosbyId().get(newAccounts.RecordTypeId).getName() == 'Tenant Account'
               &&
               (newAccounts.Existing_Unit__c != oldAccounts.Existing_Unit__c  && newAccounts.Existing_Unit__c != null && !String.ISBlank(newAccounts.Existing_Unit__c)
               || newAccounts.Tower__c != oldAccounts.Tower__c && newAccounts.Tower__c != null 
               || newAccounts.Society__c != oldAccounts.Society__c && newAccounts.Society__c != null  )){
                   UnitNames.add(newAccounts.Existing_Unit__c );
               }
        }
         System.debug('UnitNames before Update '+UnitNames);
        if(unitNames != null && unitNames.size()>0){
            Ex_DuplicantionHandlerSerivices.TenantDuplicationCheck(unitNames, newAccountList);
        }
      }

      public static void afterInsert(List<Account> accounts){
        
            String TENANT_RECORD_TYPE_NAME = 'Tenant Account';

            List<Account> tenantAccounts =  new List<Account>();
            for (Account account : accounts) {
                System.debug('account.RecordType.Name : ' + account.RecordType.Name);
                // if (account.RecordType.Name == TENANT_RECORD_TYPE_NAME) {
                    tenantAccounts.add(account);
                // }
            }

            Ex_AccountHandlerServices.createPrimaryOwnerContact(tenantAccounts);
      }

}