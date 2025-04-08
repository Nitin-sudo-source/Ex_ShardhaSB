public with sharing class Ex_BookingVerificationController {

    
    @AuraEnabled(cacheable=true)
   public static List<Booking__c> getBookings(String recordId){
       List<Booking__c> checkList = [select Id, Name,Create_Booking_Verification_CheckList__c, Booking_Date__c, Quotation__c,Booking_Type__c, Opportunity__c,
                                     Opportunity__r.Name,Tenant_Account__c,Tenant_Account__r.Name, Project__r.Name from Booking__c 
                                     where Id=:recordId];
       return checkList; 
   }
   
   
   @AuraEnabled(cacheable=true)
   public static List<Booking__c> checkCreateBookingVerificationCheckList(String recordId){
       List<Booking__c> checkList = [select Id,Create_Booking_Verification_CheckList__c, Booking_Date__c, Quotation__c,Booking_Type__c, Opportunity__c,
                                     Opportunity__r.Name,Tenant_Account__c,Tenant_Account__r.Name, Project__r.Name from Booking__c 
                                     where Id=:recordId AND Create_Booking_Verification_CheckList__c = False];
       return checkList; 
   }
   
   @AuraEnabled
   public static String changeGenarateCheckBoxValue(String recordId){ 
       try{
           List<Booking__c> bookList = [select Id,Create_Booking_Verification_CheckList__c from Booking__c where Id=:recordId]; 
           system.debug('booking is::'+bookList);
           for(Booking__c b:bookList){
               b.Id = b.Id;
               b.Create_Booking_Verification_CheckList__c = True;
               update b;
           }
           insertVerificationChecklist(bookList);
           return 'Generate Welcome Call Checklist Master changed to True';
       }catch(Exception e){
           System.debug('Exception:: '+e.getMessage());
           return e.getMessage();
       }
   }

   public static List<Booking_Verification_Checklist__c> insertVerificationChecklist(List<Booking__c> BookingList){
       List<Master_Booking_Verification_Checklist__c> welcomeCallMasterList = Master_Booking_Verification_Checklist__c.getall().values();
       List<Booking_Verification_Checklist__c> bookingVerificationChecklist = new List<Booking_Verification_Checklist__c>();
   
       if(BookingList != null && !BookingList.isEmpty()){
           for(Booking__c b:BookingList){
               for(Master_Booking_Verification_Checklist__c m:welcomeCallMasterList){
                   Booking_Verification_Checklist__c bvc = new Booking_Verification_Checklist__c();
                   bvc.Booking__c = b.Id;
                   bvc.Sequence_Number__c = m.Sequence_Number__c;
                   bvc.Category__c = m.Required_Document_Task__c;
                   bookingVerificationChecklist.add(bvc);
               }
           }
           if(!bookingVerificationChecklist.isEmpty() && bookingVerificationChecklist != null)
           insert bookingVerificationChecklist;
       }
       if(bookingVerificationChecklist != null && !bookingVerificationChecklist.isEmpty()){
           return bookingVerificationChecklist;
       }else {
           return null;
       }

   }

   @AuraEnabled
   public static List<Booking_Verification_Checklist__c> getBookingVerificationChecklistDetails(String bId) {
       try {
           List<Booking_Verification_Checklist__c> VerificationChecklistDetails = new List<Booking_Verification_Checklist__c>();
           VerificationChecklistDetails = [SELECT Id, Booking__c, Category__c, Values__c, Decision__c, Accepted__c,Sequence_Number__c FROM Booking_Verification_Checklist__c 
                                           WHERE Booking__c = :bId AND (Decision__c = '' OR Decision__c = 'Rejected') ORDER BY Sequence_Number__c ASC];
           return VerificationChecklistDetails;
       } catch (Exception e) {
           throw new AuraHandledException('Error retrieving Welcome Call Details: ' + e.getMessage());
       }
   }

   @AuraEnabled
   public static Id updateRecords(List<Booking_Verification_Checklist__c> records, List<Booking_Verification_Checklist__c> ConfirmedVerificationList, String bookId, String VerificationRemarks) {
       Decimal getRegistrationAmount = 0;
       Decimal getStampDutyAmount = 0;
       
       try {
           if (!records.isEmpty()){
               update records;
           }  
           if (!ConfirmedVerificationList.isEmpty()){
               update ConfirmedVerificationList;
           }
           
           List<Booking__c> bookingList = [
               SELECT Id, Quotation__c, Booking_Checklist_Status__c, Booking_Checklist_Remarks__c, Booking_Stage__c, Unit__c, Opportunity__c
               FROM Booking__c WHERE Id = :bookId
           ];
           
           if (bookingList.isEmpty()) {
               throw new AuraHandledException('No Booking record found for the provided ID.');
           }
           
           List<Booking_Verification_Checklist__c> welcomeList = [SELECT Id, Accepted__c FROM Booking_Verification_Checklist__c WHERE Booking__c = :bookId];
           
           boolean hasRejectedRecord = false; 
           for (Booking_Verification_Checklist__c bvc : welcomeList) {
               
               if(String.isNotBlank(VerificationRemarks)){
                bookingList[0].Booking_Checklist_Remarks__c = VerificationRemarks;    
               }
               if (bvc.Accepted__c == true) {
                   bookingList[0].Booking_Checklist_Status__c = 'Approved';
               } else {
                   hasRejectedRecord = true;
                   break;
               }
           }
           
           if (hasRejectedRecord) {
               bookingList[0].Booking_Checklist_Status__c = 'Rejected';
           }
           
           update bookingList[0];
           return bookId;
       } catch (Exception e) {
           throw new AuraHandledException('Error updating records: ' + e.getMessage());
       }
   }

}