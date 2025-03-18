public class Ex_InventoryMatrix {
    
    @AuraEnabled(cacheable=false)
    public static Opportunity getOppDetails(String oppId){
        try {
            Opportunity op = [SELECT Id, Name, Project__c, Project__r.Name, Project__r.Id FROM Opportunity WHERE Id = :oppId LIMIT 1];
            System.debug('op: ' + op);
            if (op != null && op.Project__c != null) {
                return op;
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Project__c> getProjectList() {
        try {
            List<Project__c> pList = [SELECT Id, Name FROM Project__c];
            System.debug('Project List .: ' + pList);
            if (!pList.isEmpty()) {
                return pList;
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static List<Tower__c> getTower(String projId) {
        try {
            System.debug('Project Id: ' + projId);
            List<Tower__c> tList = [SELECT Id, Name, Project__c, Project__r.Name FROM Tower__c 
                                    WHERE Project__c = :projId];
            System.debug('Tower List .:' +tList);
            if (!tList.isEmpty()) {
                return tList;
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static List<Unit__c> getUnit(string towerId) {
        try {
            System.debug('Tower Id: ' + towerId);
            List<Unit__c> uList = [SELECT Name, Configuration_Type__c, Sale_Status__c, Opportunity__c FROM Unit__c 
                                   WHERE Tower__c = :towerId];
            System.debug('Unit List .:' +uList);
            if (uList != null && !uList.isEmpty()) {
                return uList;
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static Map<String, Integer> getUnitConfigurationMapDetails(String towerId){
        Map<String, Integer> unitConfigurationMap = new Map<String, Integer>();
        List<Unit__c> uList = [Select Id, Name, Floor__c, Sale_Status__c, Configuration_Type__c, 
                               Total_carpet_Sq_Ft__c, Purpose__c, Opportunity__c from Unit__c
                               where Configuration_Type__c != null 
                               AND Tower__c =: towerId  
                               ORDER BY Configuration_Type__c ASC, Name ASC];
        System.debug('Unit List .:' +uList);
        
        if(uList != null){
            for(Unit__c u : uList){
             
                if(!unitConfigurationMap.containsKey(u.Configuration_Type__c)){
                    unitConfigurationMap.put(u.Configuration_Type__c, 1);
                    System.debug('unitConfigurationMap if .: '+unitConfigurationMap);
                }else{
                    unitConfigurationMap.put(u.Configuration_Type__c, unitConfigurationMap.get(u.Configuration_Type__c) + 1);
                    System.debug('unitConfigurationMap else .: '+unitConfigurationMap);
                }
            }
        }
        System.debug('Unit Configuration Map .: '+unitConfigurationMap);
        if(unitConfigurationMap != null &&!unitConfigurationMap.isEmpty()){
            return unitConfigurationMap;
        }else{
            return null;
        }
    }
    
    @AuraEnabled
    public static Map<String, List<Unit__c>> getUnitFloorMapDetails(String towerId){
        Map<String, List<Unit__c>> unitFloorMap = new Map<String, List<Unit__c>>();
        List<Unit__c> uList = [Select Id, Name, Floor__c, Sale_Status__c, Configuration_Type__c, 
                               Total_carpet_Sq_Ft__c, Opportunity__c /*,Unit_Facing__c, All_In_Price__c*/ from Unit__c
                               where Tower__c =: towerId  ORDER BY Floor__c DESC, Name ASC];
        system.debug('uList: '+uList);
        
        if(uList != null){
            for(Unit__c u : uList){
               
                if(!unitFloorMap.containsKey('Floor: '+u.Floor__c)) {
                    List<Unit__c> newList = new List<Unit__c>();
                    newList.add(u);
                    unitFloorMap.put('Floor: '+u.Floor__c, newList);
                } else{
                      unitFloorMap.get('Floor: '+u.Floor__c).add(u);
                    }
            }
        }
        System.debug('unitFloorMap: '+unitFloorMap);
        if(unitFloorMap != null && !unitFloorMap.isEmpty()){
        return unitFloorMap;
        }else{
            return null;
        }
        
    }
 
}