public class Ex_BlockingDetailsController {
    @AuraEnabled(cacheable=true)
    public static Blocking_Detail__c getBlockDetails(string uniId){
        system.debug('uniId is::'+uniId);
        try {
            Blocking_Detail__c blockingDetailList = [select Id, Name, Status__c , Opportunity__c,Blocked_with_token__c, Blocked_without_token__c, Blocking_Comments__c , Amount__c,
                                                      Transaction_ID__c from Blocking_Detail__c where Unit__c =:  uniId AND Status__c ='Blocked' limit 1 ];
            
            system.debug('blockingDetailList:'+blockingDetailList);
            return blockingDetailList; 
        } catch(QueryException e) {
            System.debug('Exception is : ' + e.getMessage()); 
            return null;
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<Unit__c> fetchUnits(string uniId)
    {
        List<Unit__c> unitList = [select id, Name, Tower__r.Name , Project__r.Name ,Sale_Status__c,Last_Unit_Blocking_Date__c from Unit__c where Id =: uniId];
        if(unitList != null){
            return unitList; 
        }else{
            return null;
        }
        
    }
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOppName(string oppId){
        List<Opportunity> oppList = [SELECT Id , Name FROM Opportunity where Id =: oppId] ;
        if(oppList != null){
            return oppList; 
        }else{
            return null;
        }
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getModeOfFundingPicklist() {
        Map<String, List<String>> picklistValuesMap = new Map<String, List<String>>();
        Schema.DescribeFieldResult MOPFieldResult = Blocking_Detail__c.Mode_of_Payment__c.getDescribe();
        List<Schema.PicklistEntry> ModeOfFundingPicklistEntries = MOPFieldResult.getPicklistValues();
        List<String> ModeOfFundingPicklist = new List<String>();
        for (Schema.PicklistEntry entry : ModeOfFundingPicklistEntries) {
            ModeOfFundingPicklist.add(entry.getValue());
        }
        
        picklistValuesMap.put('Mode_of_Payment__c', ModeOfFundingPicklist);
        system.debug('picklistValuesMap ' +picklistValuesMap);
        return picklistValuesMap;
    }
    @AuraEnabled
    public static Blocking_Detail__c createBlockingRecord(Boolean blockByToken, Integer amount, String blockComment, String chequeNo, String unitName, string oppId ,string MOPpicklistValue)
    {
        Blocking_Detail__c blockInfo = new Blocking_Detail__c();
        blockInfo.Blocked_with_token__c = blockByToken;
        blockInfo.Amount__c = amount;
        blockInfo.Blocking_Comments__c = blockComment;
        blockInfo.Transaction_ID__c = chequeNo;
        blockInfo.Unit__c = unitName;
        blockInfo.Opportunity__c = oppId ;
        blockInfo.Blocking_Requested_By__c = UserInfo.getUserId();
        blockInfo.Mode_of_Payment__c = MOPpicklistValue ;
        try{
            insert blockInfo;
        }
        catch(exception ex)
        {
            throw new AuraHandledException(ex.getMessage());
        }
        blockInfo.Status__c = 'Blocked';
        update blockInfo;
        
        if (String.isNotBlank(unitName)) {
            Unit__c unit = [SELECT Id, Name, Sale_Status__c, Last_Unit_Blocking_Date__c FROM Unit__c WHERE Id = :unitName LIMIT 1];
            if (unit != null) {
                unit.Sale_Status__c = blockByToken ? 'Sale Hold with Money' : 'Sale Hold without Money';
                unit.Last_Unit_Blocking_Date__c = System.now();
                if (String.isNotBlank(oppId)) {
                    unit.Opportunity__c = oppId;  
                }
                update unit;
            }
        }
        return blockInfo;
    }

    @AuraEnabled
    public static Blocking_Detail__c unblockLogic(String blockId,String unblockComment)
    {
        Blocking_Detail__c unblock=[select id,Status__c,Unit__c from Blocking_Detail__c where id=:blockId AND Status__c ='Blocked' limit 1];
        Unit__c unit=[select id,Name,Sale_Status__c,Blocking_Comments__c from Unit__c where Id=:unblock.Unit__c];
        unblock.Status__c='Released';
        unit.Sale_Status__c='Vacant';
        unit.Blocking_Comments__c = unblockComment;
        unit.Opportunity__c = null ;
        update unit;
        update unblock;
        return unblock;
    }

}