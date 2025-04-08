/**
 * @description       :
 * @author            : nitinSFDC@exceller.SFDoc
 * @group             :
 * @last modified on  : 08-04-2025
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
    
    @AuraEnabled(cacheable=false)
    public static List<BookingWrapper> getBookings(String ProjectId, String TowerId){
        List<BookingWrapper> bList = new List<BookingWrapper>();
        List<Booking__c> bkList = new List<Booking__c>();
        bkList = [SELECT Id, Name, Quotation__c, Quotation__r.Name, Project__c, Tower__c, Unit__r.Name, Primary_Applicant_Name__c from Booking__c where Project__c =: ProjectId AND Tower__c =: TowerId];
        for(Booking__c bk: bkList){
            BookingWrapper bw = new BookingWrapper();
            bw.booking = bk;
            //bw.tower = bk.Tower__c;
            bList.add(bw);
        }
        System.debug('BkList: ' + 'bList:: ' + bList);
        return bList;
    }
    
    // @AuraEnabled(cacheable=false)
    // public static List<DemandWrapper> fetchDemands(String ProjectId, String TowerId){
        //     List<DemandWrapper> dList = new List<DemandWrapper>();
        //     List<Booking__c> bkList = new List<Booking__c>();
        //     bkList = [SELECT Id, Name, Project__c, Tower__c, Unit__r.Name, Primary_Applicant_Name__c from Booking__c where Project__c =: ProjectId AND Tower__c =: TowerId];
        
        //     List<Demand__c> demandList = new List<Demand__c>();
        //     demandList = getDemandDetails();
        //     for(Demand__c demand: demandList){
            //             DemandWrapper dw = new DemandWrapper();
            //             dw.demand = demand;
            //             dList.add(dw);
            
        //     }
        //     System.debug('dList: ' + 'demandList: ' + demandList);
        //     return dList;
    // }
    

    @AuraEnabled
    public static List<PaymentMilestoneWrapper> getPMDetails(String qId){
        List<PaymentMilestoneWrapper> pmWrapperList = new List<PaymentMilestoneWrapper>();
        List<Payment_Milestone__c> pmList = new List<Payment_Milestone__c>();
        String[] types = new String[]{'Payment_Milestone__c'};
        string queryFields = '';
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        
        for(Schema.DescribeSobjectResult res : results) {
            string sObjectname = res.getName();
            Map <String, Schema.SObjectField> fieldMap = res.fields.getMap();
            
            for(Schema.SObjectField sfield : fieldMap.Values()) {
                schema.describefieldresult dfield = sfield.getDescribe();
                String fieldLabel = dfield.getLabel();
                
                if(queryFields == null || queryFields == '') {
                    queryFields = dField.getName();
                } else {
                    queryFields = queryFields + ', ' + dField.getName();
                }
            }
        }
        System.debug('qId : ' + qId);
        String soqlQuery = 'Select ' + queryFields  + ' from Payment_Milestone__c Where Quotation__c = :qId';
        system.debug(soqlQuery);
        pmList = Database.query(soqlQuery);
        if(!pmList.isEmpty() && pmList != null){
            for(Payment_Milestone__c pm: pmList){
                PaymentMilestoneWrapper dw = new PaymentMilestoneWrapper();
                dw.paymentmilestone = pm;
                pmWrapperList.add(dw);
                
            }
            return pmWrapperList;
        }else{
            return null;
        }
    }

    @AuraEnabled
    public static List<DemandWrapper> getDemandDetails(String bId, Date startDate, Date endDate, String mType){
        List<DemandWrapper> demandWrapperList = new List<DemandWrapper>();
        List<Demand__c> dlist = new List<Demand__c>();
        String[] types = new String[]{'Demand__c'};
        string queryFields = '';
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        
        for(Schema.DescribeSobjectResult res : results) {
            string sObjectname = res.getName();
            Map <String, Schema.SObjectField> fieldMap = res.fields.getMap();
            
            for(Schema.SObjectField sfield : fieldMap.Values()) {
                schema.describefieldresult dfield = sfield.getDescribe();
                String fieldLabel = dfield.getLabel();
                
                if(queryFields == null || queryFields == '') {
                    queryFields = dField.getName();
                } else {
                    queryFields = queryFields + ', ' + dField.getName();
                }
            }
        }
        System.debug('bId : ' + bId);
        System.debug('startDate : ' + startDate);
        System.debug('endDate : ' + endDate);
        System.debug('mType : ' + mType);
                
        // String soqlQuery = 'Select ' + queryFields  + ' , Booking__r.Primary_Applicant_Name__c , Booking__r.Unit__r.Name, Booking__r.Name from Demand__c Where Booking__c = :bId';
        // system.debug(soqlQuery);
        // dlist = Database.query(soqlQuery);


       
        String soqlQuery = 'SELECT ' + queryFields + ', Booking__r.Primary_Applicant_Name__c, Booking__r.Unit__r.Name, Booking__r.Name FROM Demand__c WHERE Booking__c = :bId';
        
        if (startDate != null) {
            soqlQuery += ' AND CreatedDate >= :startDate';
        }
        if (endDate != null) {
            soqlQuery += ' AND CreatedDate <= :endDate';
        }
        
        if (!String.isBlank(mType) && mType != 'All') {
            soqlQuery += ' AND Payment_Milestone__c = :mType';
        }
        
        System.debug('Final SOQL: ' + soqlQuery);
        dlist = Database.query(soqlQuery);
        System.debug('dlist: '+dlist);

        
        if(!dlist.isEmpty() && dlist != null){
            for(Demand__c demand: dlist){
                System.debug('demand: '+demand);
                DemandWrapper dw = new DemandWrapper();
                dw.demand = demand;
                dw.customerName = demand.Booking__r.Primary_Applicant_Name__c;
                dw.approvalStatus = demand.Demand_Approval_Status__c;
                demandWrapperList.add(dw);
                
            }
            return demandWrapperList;
        }else{
            return null;
        }
    }
    
    
    
    
    public class BookingWrapper {
        @AuraEnabled public Booking__c booking { get; set; }
        
        public BookingWrapper() {
            booking = new Booking__c();
        }
    }
    
    public class DemandWrapper {
        @AuraEnabled public Demand__c demand { get; set; }
        @AuraEnabled public String approvalStatus { get; set; }
        @AuraEnabled public String customerName { get; set; }
        public DemandWrapper() {
            demand = new Demand__c();
            approvalStatus = 'Not Approved';
            customerName = this.customerName;
        }
    }
    public class PaymentMilestoneWrapper {
        @AuraEnabled public Payment_Milestone__c paymentmilestone { get; set; }
        public PaymentMilestoneWrapper() {
            paymentmilestone = new Payment_Milestone__c();
        }
    }
    
    
}