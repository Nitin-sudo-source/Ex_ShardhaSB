public class Ex_DemandManagementServices {
    public static void raiseDemand(Payment_Milestone__c pm) {
        if (pm != null) {
            try {
                // Step 1: Update Payment Milestone
                pm.Is_Raised__c = true;
                pm.Demand_Raised_Date__c = System.today();
                
                Decimal tdsPercentage = getTDSPercentage(pm.Quotation__r.Booking__r.Project__c);
                
                Decimal onAccountBalance = 0;
                onAccountBalance = getOnAccountBalance(pm.Quotation__r.Booking__c);
                system.debug('onAccountBalance: '+onAccountBalance);
                
                // Step 2: Create Demand Record
                Demand__c d = new Demand__c();
                d.Demand_Type__c = 'Flat Cost';
                d.Booking__c = pm.Quotation__r.Booking__c;
                d.Quotation__c = pm.Quotation__c;
                d.Payment_Milestone__c = pm.Id;
                d.Milestone_Name__c = pm.Milestone_Name__c;
                d.Invoice_Date__c = pm.Due_Date__c;
                d.Due_Date__c = pm.Due_Date__c.addDays(7); 
                d.Demand_Status__c = 'Raised';
                d.Customer_Name__c = pm.Quotation__r.Booking__r.Primary_Applicant_Title__c + ' ' + pm.Quotation__r.Booking__r.Primary_Applicant_Name__c;
                d.Customer_Mobile__c = pm.Quotation__r.Booking__r.Primary_Applicant_Mobile__c;
                d.Customer_Email__c = pm.Quotation__r.Booking__r.Primary_Applicant_Email__c;
                
                
                for (Integer i = 1; i <= 5; i++) {
                    if ((String) pm.get('Charge_Bucket_' + i + '__c') != null && String.isNotBlank((String) pm.get('Charge_Bucket_' + i + '__c'))) {
                        if (((String) pm.get('Charge_Bucket_' + i + '__c')).equalsIgnoreCase('Agreement Value')) {
                            if(pm.Quotation__r.Booking__r.Agreement_Value__c >= pm.Quotation__r.Booking__r.Project__r.TDS_Threshold__c) {
                                d.TDS_Value_Demanded__c = (((Decimal) pm.get('Charge_Bucket_' + i + '_Amount__c') / 100) * tdsPercentage).setScale(0,RoundingMode.HALF_UP);
                                d.Agreement_Value_Demanded__c = ((Decimal) pm.get('Charge_Bucket_' + i + '_Amount__c'));    /* As Per Client Requirement (- d.TDS_Value_Demanded__c);*/
                            } else {
                                d.Agreement_Value_Demanded__c = (Decimal) pm.get('Charge_Bucket_' + i + '_Amount__c');
                            }
                            d.Agreement_Value_Tax_Demanded__c = (Decimal) pm.get('Charge_Bucket_' + i + '_Total_Tax__c');
                            d.Total_Amount_Demanded__c = (Decimal) pm.get('Charge_Bucket_' + i + '_Amount__c');
                            d.Total_Tax_Demanded__c = (Decimal) pm.get('Charge_Bucket_' + i + '_Total_Tax__c');
                        } else if (((String) pm.get('Charge_Bucket_' + i + '__c')).equalsIgnoreCase('Other Charges')) {
                            d.Other_Charges_Demanded__c = (Decimal) pm.get('Charge_Bucket_' + i + '_Amount__c');
                            d.Other_Charges_Tax_Demanded__c = (Decimal) pm.get('Charge_Bucket_' + i + '_Total_Tax__c');
                        }
                    }
                }
                
                // TODO :
                // Step 2.1: Create Other Charges Demanded
                if (pm.Is_Possession_Milestone__c) {
                    if (pm.Quotation__r != null && pm.Quotation__r.Modified_Other_Charges__c != null) {
                        
                        try {
                            d.Other_Charges_Demanded__c = pm.Quotation__r.Modified_Other_Charges__c; // Amount without GST
                            d.Other_Charges_Tax_Demanded__c = pm.Quotation__r.Modified_Other_Charges_Tax__c; // Only GST amount
                        } catch (Exception ex) {
                            System.debug('Error: ' + ex.getMessage());
                        }
                    } else {
                        d.Other_Charges_Demanded__c = 0;
                        d.Other_Charges_Tax_Demanded__c = 0;
                    }
                }
                
                
                // Step 4: Insert Demand & Update PM
                Database.SaveResult insertResult = Database.insert(d, false);
                Database.SaveResult updateResult = Database.update(pm, false);
                
                // Step 4.1: Verify successful insert
                Set<Id> demandIdSet = new Set<Id>();
                if (!insertResult.isSuccess()) {
                    for (Database.Error error : insertResult.getErrors()) {
                        System.debug('Insert Error: ' + error.getMessage());
                    }
                }
                
                // Step 4.2: Verify successful update
                if (!updateResult.isSuccess()) {
                    for (Database.Error error : updateResult.getErrors()) {
                        System.debug('Update Error: ' + error.getMessage());
                    }
                }
                // Step 4: Handle On-Account Balance
                if (onAccountBalance > 0) {
                    Set<Id> rIdSet = getOnAccountBalanceReceipts(pm.Quotation__r.Booking__c);
                    if (rIdSet != null && !rIdSet.isEmpty()) {
                        // TODO : 
                        // Ex_ReceiptHandlerServices.receiptApporation(rIdSet);
                    }
                }
            } catch (Exception ex) {
                System.debug('Error: ' + ex.getMessage());
            }
        }
    }
    
    public static Decimal getOnAccountBalance(Id bId) {
        Decimal onAccountBalance = 0;
        List<Receipt__c> rList = [SELECT Id, Name, On_Account_Money__c FROM Receipt__c WHERE On_Account_Money__c > 0
                                  AND Booking__c = :bId ORDER BY Receipt_Date__c ASC];
        if(!rList.isEmpty() && rList != null){
            for (Receipt__c r : rList) {
                onAccountBalance += r.On_Account_Money__c;
            }
        }
        return onAccountBalance;
    }
    
    public static Set<Id> getOnAccountBalanceReceipts(Id bId) {
        Set<Id> rIdSet = new Set<Id>();
        List<Receipt__c> rList = [SELECT Id, Name, On_Account_Money__c FROM Receipt__c WHERE On_Account_Money__c > 0
                                  AND Booking__c = :bId ORDER BY Receipt_Date__c ASC];
        if(!rList.isEmpty() && rList != null){
            for (Receipt__c r : rList) {
                rIdSet.add(r.Id);
            }
        }
        return rIdSet;
    }
    

    // Returns the TDS percentage for the given project ID
    public static Decimal getTDSPercentage(Id pId) {
        
        Decimal tdsPercentage = 0;

        List<Project__c> pList = [SELECT Id, TDS_Percentage__c FROM Project__c WHERE Id = :pId];
        if (!pList.isEmpty()) {
            tdsPercentage = pList[0].TDS_Percentage__c;
        }

        return tdsPercentage;
    }
}