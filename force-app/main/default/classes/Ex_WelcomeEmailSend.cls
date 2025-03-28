/**
 * @description       : 
 * @author            : nitinSFDC@exceller.SFDoc
 * @group             : 
 * @last modified on  : 28-03-2025
 * @last modified by  : nitinSFDC@exceller.SFDoc
**/
public with sharing class Ex_WelcomeEmailSend {
    public Ex_WelcomeEmailSend() {

    }

    @AuraEnabled
public static EmailTestResponse sendEmailOnClick(Id recordId) {
    try {
        // Initialize response object
        EmailTestResponse response = new EmailTestResponse();
        
        // Debug record ID
        System.debug('RecordId: ' + recordId);
        
        // Get Org Wide Email Address
        OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName 
                                  FROM OrgWideEmailAddress 
                                  WHERE DisplayName = 'Send Welcome Email'
                                  LIMIT 1];
        response.orgWideEmail = owea;
        System.debug('OrgWideEmailAddress: ' + owea);

        // Get Booking Information
        Booking__c bk = getBookingInfo(recordId);
        response.bookingRecord = bk;
        System.debug('Booking: ' + bk);
        
        if(bk == null) {
            response.isSuccess = false;
            response.errorMessage = 'No booking found with ID: ' + recordId;
            return response;
        }

        // Determine recipient
        String recipientEmail = bk.Primary_Applicant_Email__c != null 
                             ? bk.Primary_Applicant_Email__c 
                             : bk.Owner.Email;
        response.recipientEmail = recipientEmail;
        
        if(String.isBlank(recipientEmail)) {
            response.isSuccess = false;
            response.errorMessage = 'No email address available for this booking';
            return response;
        }

        // Create email body
        String body = 'Dear Customer,<br/><br/>';
        body += 'Warm Greetings from Shardha Live Space!<br/>';
        body += 'We feel truly honoured to be part of our association with you and we welcome you to the Shardha Live Space family.<br/>';
        body += '<br/><br/>Thanks & Regards,<br/>Shardha Live Space';
        
        response.emailBody = body;
        response.emailSubject = 'Welcome Email';
        response.isSuccess = true;
        
        return response;
        
    } catch(Exception e) {
        System.debug('Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        EmailTestResponse errorResponse = new EmailTestResponse();
        errorResponse.isSuccess = false;
        errorResponse.errorMessage = e.getMessage();
        errorResponse.stackTrace = e.getStackTraceString();
        return errorResponse;
    }
}

public class EmailTestResponse {
    @AuraEnabled public Boolean isSuccess { get; set; }
    @AuraEnabled public String errorMessage { get; set; }
    @AuraEnabled public String stackTrace { get; set; }
    @AuraEnabled public Booking__c bookingRecord { get; set; }
    @AuraEnabled public String recipientEmail { get; set; }
    @AuraEnabled public String emailSubject { get; set; }
    @AuraEnabled public String emailBody { get; set; }
    @AuraEnabled public OrgWideEmailAddress orgWideEmail { get; set; }

}

    // @AuraEnabled
    // public static String sendEmailOnClick(Id recordId) {
    //     String getResponse = '';
    //     try {
    //         // Debug record ID
    //         System.debug('RecordId: ' + recordId);
            
    //         // Get Org Wide Email Address
    //         OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName 
    //                                   FROM OrgWideEmailAddress 
    //                                   WHERE DisplayName = 'Send Welcome Email'
    //                                   LIMIT 1];
    //         System.debug('OrgWideEmailAddress: ' + owea);
    
    //         // Get Booking Information
    //         Booking__c bk = getBookingInfo(recordId);
    //         System.debug('Booking: ' + bk);
            
    //         if(bk == null) {
    //             throw new AuraHandledException('No booking found with ID: ' + recordId);
    //         }
    
    //         // Determine recipient
    //         String recipientEmail = bk.Primary_Applicant_Email__c != null 
    //                              ? bk.Primary_Applicant_Email__c 
    //                              : bk.Owner.Email;
            
    //         if(String.isBlank(recipientEmail)) {
    //             throw new AuraHandledException('No email address available for this booking');
    //         }
    
    //         // Create email
    //         Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
    //         // Set recipients
    //         email.setToAddresses(new List<String>{recipientEmail});
            
    //         // Set email content
    //         String body = 'Dear Customer,<br/><br/>';
    //         body += 'Warm Greetings from Shardha Live Space!<br/>';
    //         body += 'We feel truly honoured to be part of our association with you and we welcome you to the Shardha Live Space family.<br/>';
    //         body += '<br/><br/>Thanks & Regards,<br/>Shardha Live Space';
            
    //         email.setSubject('Welcome Email');
    //         email.setHtmlBody(body);
            
    //         // Set Org Wide Email Address if available
    //         // if(owea != null) {
    //         //     email.setOrgWideEmailAddressId(owea.Id);
    //         // }
    
    //         // Send email (only in non-test context)
    //         // if(!Test.isRunningTest()) {
    //         //     Messaging.sendEmail(new List<Messaging.Email>{email});
    //         // }
    //         getResponse =  bk.Id;
    //     } catch(Exception e) {
    //         System.debug('Error sending email: ' + e.getMessage() + '\n' + e.getStackTraceString());
    //         getResponse =  (e.getMessage() + '\n' + e.getStackTraceString());
    //         throw new AuraHandledException('Failed to send email: ' + e.getMessage());


    //     }
    //     return getResponse;
    // }
    

    public static Booking__c getBookingInfo(Id tId) {
        List<Booking__c> bkList = new List<Booking__c>();
        String[] types = new String[]{'Booking__c'};
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
        String soqlQuery = 'Select ' + queryFields  + ' from Booking__c Where Id = \''+tId+'\' Limit 1';
        system.debug(soqlQuery);
        bkList = Database.query(soqlQuery);
        if (bkList.size() > 0) {
            return bkList[0];
        } else {
            return null;
        }
    }

}