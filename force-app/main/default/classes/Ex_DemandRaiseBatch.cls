/*-------------------------------------------
Project: Shraddha Lifespaces
Created By: Exceller Tech
Last Modified Date: 2023-10-04
//-------------------------------------------*/
global class Ex_DemandRaiseBatch implements Database.Batchable <sObject>, Database.Stateful, Schedulable {
    global String query;
    global Date cDate = system.today();
    global Booking__c bid;
    global Set<Id> pmIdSet = new Set<Id>(); 
    
    global Ex_DemandRaiseBatch() {
        String tempQuery = '';
        for (Integer i = 1; i <= 5; i++) {
            tempQuery += 'Charge_Bucket_' + i + '__c' + ',';
            tempQuery += 'Charge_Bucket_' + i + '_Amount__c' + ',';
            tempQuery += 'Charge_Bucket_' + i + '_Percentage__c' + ',';
            tempQuery += 'Charge_Bucket_' + i + '_CGST__c' + ',';
            tempQuery += 'Charge_Bucket_' + i + '_SGST__c' + ',';
            tempQuery += 'Charge_Bucket_' + i + '_Total_Tax__c' + ',';
        }
        
        //remove the last character only if its a comma.
        if (tempQuery.length() > 0 && tempQuery.substring(tempQuery.length() - 1).equals(','))   
            tempQuery = tempQuery.substring(0, tempQuery.length() - 1);
        query = 'SELECT Id, Name, Construction_Stage__c, Construction_Stage_Description__c, Deduct_Token__c, Demand_Raised_Date__c,'
            +' Due_Date__c, Is_Due__c, Is_Raised__c, Milestone_Complete_At_Booking__c, Milestone_Name__c, Milestone_Type__c, Is_Possession_Milestone__c,'
            +' Quotation__r.Booking__r.Primary_Applicant_Title__c, Quotation__r.Booking__r.Primary_Applicant_Name__c,'
            +' Quotation__r.Booking__r.Primary_Applicant_Mobile__c, Quotation__r.Booking__r.Primary_Applicant_Email__c,'
            +' Quotation__r.Booking__r.Project__r.Last_Demand_No__c, Quotation__r.Booking__r.Project__r.Starting_Demand_No__c,'
            +' Quotation__r.Booking__r.Project__r.Name,Quotation__r.Booking__r.Business_Region__c,Quotation__r.Booking__r.Project__r.TDS_Threshold__c,'
            +' Quotation__r.Booking__r.Project__r.Invoice_Number_Format__c,Quotation__r.Modified_Total_Other_Charges__c,Quotation__r.GST_On_Other_Charges__c,'
            +' Quotation__r.Booking__r.Agreement_Value__c,Number_of_Days__c, Quotation__c, Sequence_No__c, ' + tempQuery
            +' FROM Payment_Milestone__c'
            +' WHERE ((Milestone_Type__c = \'Date Linked\' AND Due_Date__c <= TODAY)'
            +' OR (Milestone_Type__c = \'Registration Linked\' AND Due_Date__c <= TODAY)'
            +' OR (Milestone_Type__c = \'Construction Linked\' AND Quotation__r.Booking__r.Registration_Status__c = \'Registration Completed\' AND Due_Date__c <= TODAY'
            +' AND Construction_Stage__r.Is_Completed__c = true) OR Is_Due__c = true)'
            +' AND Quotation__c != null'
            +' AND Quotation__r.Booking__c != null'
            +' AND Quotation__r.Unit__c != null'
            +' AND Quotation__r.Opportunity__r.Opportunity_Stage__c = \'Booked\''
            +' AND Quotation__r.Unit__r.Sales_Status__c = \'Booked\''
            +' AND Is_Raised__c = false'
            +' AND Quotation__r.Booking__r.Booking_Stage__c = \'Booking Confirmed\''
            +' ORDER BY Due_Date__c ASC';
        
        system.debug('query is :::: ' + query);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('query is :::: '+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext info, List<Payment_Milestone__c> pmList) {
        system.debug('pmList: '+pmList);
        for(Payment_Milestone__c pm: pmList) {
            system.debug('Milestone Id:' + pm.Id);
            Ex_DemandManagementServices.raiseDemand(pm);
            pmIdSet.add(pm.Id);
        }
    }
    
    global void finish(Database.BatchableContext info) {  
        system.debug('pmIdSet in finish: ' + pmIdSet);
        if (pmIdSet != null && !pmIdSet.isEmpty()) {
            // TODO : 
            // System.enqueueJob(new Ex_SendDemandLetterQueueable(pmIdSet));
        } else {
            system.debug('No demand IDs to process.');
        }   
    }   
    
    global void execute(SchedulableContext sc) {
        Ex_DemandRaiseBatch b = new Ex_DemandRaiseBatch(); 
        if (!Test.isRunningTest()){
            database.executebatch(b,1);
        }
    }
}