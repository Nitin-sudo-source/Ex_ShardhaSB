/**
 * @description       :
 * @author            : nitinSFDC@exceller.SFDoc
 * @group             :
 * @last modified on  : 01-04-2025
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
            System.debug('RecordId: ' + recordId);
            
            OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName 
                                      FROM OrgWideEmailAddress 
                                      WHERE DisplayName = 'Send Welcome Email'
                                      LIMIT 1];
            response.orgWideEmail = owea;
            System.debug('OrgWideEmailAddress: ' + owea);
            
            Booking__c bk = getBookingInfo(recordId);
            response.bookingRecord = bk;
            System.debug('Booking: ' + bk);
            
            if (bk == null) {
                response.isSuccess = false;
                response.errorMessage = 'No booking found with ID: ' + recordId;
                return response;
            }
            response.quotationId = bk.Quotation__c;
            String recipientEmail = bk.Primary_Applicant_Email__c != null
                ? bk.Primary_Applicant_Email__c
                : bk.Owner.Email;
            response.recipientEmail = recipientEmail;
            
            if (String.isBlank(recipientEmail)) {
                response.isSuccess = false;
                response.errorMessage = 'No email address available for this booking';
                return response;
            }
            String body = '';
            String subject = '';
            
            if(bk.Booking_Type__c != null && bk.Booking_Type__c.equalsIgnoreCase('Opportunity Based')){
                subject = '<b> Welcome to Shardha Live Space - Project Confirmation for '+ bk.Project__r.Name +'</b>';
                body = 'Dear '+ bk.Primary_Applicant_Name__c  +'<br/><br/>';
                body += 'Warm Greetings from Shardha Live Space!<br/>';
                body += 'We are thrilled to welcome you to '+ 'Shardha Live Space' +'! We appreciate the trust you have placed in us to handle your '+ 'NA Project Type' +'project, and we are excited to get started..<br/>';
                body += 'Summary of Your Project:<br/>';
                body += '<br/>Please find the details of your booking below:<br/><br/>';
                body += '<ul>';
                body += '<li> <b>Project Name:</b> '+ bk.Project__r.Name +'</li>';
                body += '<li> <b>Booking Date:</b> '+ bk.Booking_Date__c +'</li>';
                body += '<li> <b>Unit:</b> '+ bk.Unit__r.Name +'</li>';
                body += '<li> <b>Floor:</b> '+ bk.Unit__r.Floor__c +'</li>';
                body += '<li> <b>Total Amount:</b> '+  Ex_InventoryPriceManagementServices.currencyFormat(bk.Agreement_Value__c) +'</li>';
                body += '</ul>';
                body += '<br/>';
            } else  if(bk.Booking_Type__c != null && bk.Booking_Type__c.equalsIgnoreCase('Tenant Based')){
                subject = '<b> Welcome to Shardha Live Space -  Rehabilitation Project Details for '+ bk.Tenant_Account__r.Name +'</b>';
                body = 'Dear '+ bk.Tenant_Account__r.Name  +'<br/><br/>';
                body = 'We are pleased to welcome you to Shardha Live Space! We appreciate your cooperation and understanding as we work on the rehabilitation project at ____________________ (Property Address). Our goal is to ensure that the process is as smooth and convenient as possible for you <br/><br/>';
                body += '<b>Summary of Rehabilitation project:<b><br/>';
                body += '<br/>Please find the details of your Rehabilitation project below:<br/><br/>';
                body += '<ul>';
                body += '<li> <b>Project Name:</b> '+ bk.Project__r.Name +'</li>';
                body += '<li> <b>Start Date of Rent:</b> '+ bk.Booking_Date__c +'</li>';
                body += '<li> <b>End Date of Rent:</b> '+ bk.Booking_Date__c +'</li>';
                body += '</ul>';
                body += '<br/>';
            }
            
            
            body += '<b><u>Contact Information:<u></b><br/>';
            body += 'For any support or queries, please do not hesitate to contact us:<br/>';
            body += '<ul>';
            body += '<li> <b>Contact Person:</b> '+ bk.Project__r.Name +'</li>';
            body += '<li> <b>Email:</b> '+ bk.Booking_Date__c +'</li>';
            body += '<li> <b>Phone:</b> '+ bk.Unit__r.Name +'</li>';
            body += '</ul>';
            body += '<br/>';
            body += '<u>Attachments:</u><br/><br/>';
            body += 'We have included the following documents for your reference:<br/><br/>';
            body += '<ul>';
            if(bk.Booking_Type__c != null && bk.Booking_Type__c.equalsIgnoreCase('Opportunity Based')){
            body += '<li> <b>Signed Booking Form: This document confirms the project details and terms agreed upon.</b></li>';
            body += '<li> <b>Project Timeline: A detailed timeline outlining key milestones and deadlines</b></li>';
            body += '<li> <b>Payment Schedule: A breakdown of the payment terms and due dates.</b></li>';
            body += '</ul>';
            } else  if(bk.Booking_Type__c != null && bk.Booking_Type__c.equalsIgnoreCase('Tenant Based')){
                body += '<li> <b>Project Timeline: A detailed timeline outlining key milestones and deadlines</b></li>';


            }
            body += '<br/>';
            body += 'Please review these documents carefully and let us know if you have any questions.<br/>';

            if(bk.Booking_Type__c != null && bk.Booking_Type__c.equalsIgnoreCase('Opportunity Based')){

            body += 'Thank you again for choosing '+ 'Shardha Live Space' +'. We look forward to working with you and delivering an exceptional project experience.<br/>';
            } else  if(bk.Booking_Type__c != null && bk.Booking_Type__c.equalsIgnoreCase('Tenant Based')){
                body += 'Thank you for your understanding and cooperation. We are committed to minimizing disruptions and ensuring your safety and comfort throughout the project.<br/>';
            }


            

            
            
            
            
            
            
            
            body += '<br/><br/>Thanks & Regards,<br/> For Shardha Live Space';
            body += '<br/><br/>';
            body += 'Authorized Signatory';
            
            // Generate PDF Attachment
            PageReference pdf = Page.Ex_PrintQuotationVF;
            pdf.getParameters().put('qId', bk.Quotation__c);
            Blob b = pdf.getContentAsPDF();
            
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setContentType('application/pdf');
            efa.setFileName('Quotation_' + bk.Quotation__c + '.pdf');
            efa.setInline(false);
            efa.setBody(b);
            response.emailAttachment = EncodingUtil.base64Encode(b);
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{recipientEmail});
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setSubject('Welcome Email');
            mail.setHtmlBody(body);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{efa});
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
            
            if (results[0].isSuccess()) {
                response.isSuccess = true;
            } else {
                response.isSuccess = false;
                response.errorMessage = 'Email failed to send: ' + results[0].getErrors()[0].getMessage();
            }
            
            return response;
            
        } catch (Exception e) {
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
        @AuraEnabled public String emailAttachment { get; set; } // Stores Base64 encoded PDF file
        @AuraEnabled public Id quotationId { get; set; } // Stores related Quotation record ID
    }
    
    
    
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
        String soqlQuery = 'Select ' + queryFields  + ' , Project__r.Name, Unit__r.Name, Unit__r.Floor__c, Tenant_Account__r.Name from Booking__c Where Id = \''+tId+'\' Limit 1';
        system.debug(soqlQuery);
        bkList = Database.query(soqlQuery);
        if (bkList.size() > 0) {
            return bkList[0];
        } else {
            return null;
        }
    }
    
}