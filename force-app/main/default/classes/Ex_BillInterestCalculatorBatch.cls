/*
    * Author        : Exceller Tech
    * Last Modified : 04/03/2025
    * Description   : Calculates the Interest for the Bills whose due date is passed until 
    *                 whole amount is paid (refering Remaining_Amount__c)
*/

public class Ex_BillInterestCalculatorBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        
        return Database.getQueryLocator([ 
            SELECT Id, Name, Bill_Stage__c, Due_Date__c, Amount__c, Remaining__c, 
                   Charge_Name__c, Term_Sheet__r.Rent_Interest__c 
            FROM Bill__c 
            WHERE Bill_Stage__c = 'Actual' AND 
                  Term_Sheet__c != null AND 
                  Tenant__c != null AND 
                  Due_Date__c < :System.today() AND 
                  Amount__c != null AND 
                  Remaining__c > 0 
        ]);
    }


    public void execute(Database.BatchableContext batchableContext, List<Bill__c> bills){

        for (Bill__c bill : bills) {
            
            Decimal chargeAmount = bill.Amount__c;

            Date startDate = bill.Due_Date__c;
            Date endDate = System.today();
            Integer noOfDays = getDaysDifference(startDate, endDate);

            Decimal yearlyInterestPercentage = getYearlyInterestPercentage(bill);
            Decimal dailyInterestPercentage = yearlyInterestPercentage/365;

            Double totalInterest = (noOfDays*dailyInterestPercentage*chargeAmount)/100;
            bill.Interest_Amount__c = totalInterest;
        }

        if (bills != null && !bills.isEmpty()) {
            Database.update(bills);
        }
    }


    public void finish(Database.BatchableContext batchableContext){
        System.debug('Bill Interest Calculator Batch executed sucessfully !');
    }


    // Handle Scheduled Interest Bill Batch
    public void execute(System.SchedulableContext schedulableContext){
        Ex_BillInterestCalculatorBatch billInterestCalculator =  new Ex_BillInterestCalculatorBatch();
        Database.executeBatch(billInterestCalculator, 200);
    }


    // --- Utility Methods ---
    public static Integer getDaysDifference(Date startDate, Date endDate){
        return startDate.daysBetween(endDate);
    }


    // Returns 'Interest Percentage' for specified bill based on Bill Type
    // as we have charge wise Interest rates maintained on Term Sheet
    public static Decimal getYearlyInterestPercentage(Bill__c bill){

        String chargeName = bill.Charge_Name__c;

        if(chargeName == 'Rental Charges'){
            return bill.Term_Sheet__r.Rent_Interest__c;
        }
        if(chargeName == 'Transport charges'){
            return bill.Term_Sheet__r.Transport_Interest__c;
        }
        if(chargeName == 'Corpus Fund 1' || chargeName == 'Corpus Fund 2' || chargeName == 'Corpus Fund 3' ||
           chargeName == 'Corpus Fund 4' || chargeName == 'Corpus Fund 5'){
            return bill.Term_Sheet__r.Corpus_Interest__c;
        }
        if(chargeName == 'Brokerage'){
            return bill.Term_Sheet__r.Brokerage_Interest__c;
        }
        if(chargeName == 'Misc/Other'){
            return bill.Term_Sheet__r.MISC_Interest__c;
        }

        return null;
    }
}