/**
 * @description       : 
 * @author            : nitinSFDC@exceller.SFDoc
 * @group             : 
 * @last modified on  : 07-04-2025
 * @last modified by  : nitinSFDC@exceller.SFDoc
**/
public with sharing class Ex_BulkDemandApprovalDashboard {
    public Ex_BulkDemandApprovalDashboard() {

    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProject(){
        List<Project__c> plist=[select Id, Name FROM Project__c];
        return plist;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Tower__c> getTower(String ProjectId){
        List<Tower__c> tlist=[select Id, Name,Project__c FROM Tower__c WHERE Project__r.id =: ProjectId];
        return tlist;
    }
}