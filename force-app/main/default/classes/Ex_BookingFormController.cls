public class Ex_BookingFormController {

    
    // --- Used for Getting and Setting data ---
    public class BookingDetails{
        @AuraEnabled public String opportunityName {get; set;}
        @AuraEnabled public String projectName {get; set;}
        @AuraEnabled public String towerName {get; set;}
        @AuraEnabled public String unitName {get; set;}
        @AuraEnabled public String floorNo {get; set;}
        @AuraEnabled public String totalCarpetArea {get; set;}
        @AuraEnabled public Date bookingDate {get; set;}
        @AuraEnabled public String modeOfFunding {get; set;}
        @AuraEnabled public String anyOtherOffers {get; set;}
        @AuraEnabled public String remarks {get; set;}
        @AuraEnabled public String isLoanSanctioned {get; set;}
        @AuraEnabled public String loanSanctionedBankName {get; set;}
        @AuraEnabled public String loanSactionedPreferredBankName {get; set;}
        @AuraEnabled public Decimal sanctionedAmount {get; set;}
        @AuraEnabled public Decimal ownContributionAmount {get; set;}
        @AuraEnabled public String bookingSource {get; set;}
        @AuraEnabled public String bookingSubsource {get; set;}
        @AuraEnabled public String channelPartnerName {get; set;}
        @AuraEnabled public String channelPartnerMobile {get; set;}
        @AuraEnabled public String channelPartnerEmail {get; set;}
        @AuraEnabled public String channelPartnerReraNo {get; set;}
        @AuraEnabled public String channelPartnerPOC {get; set;}

        public BookingDetails(){
            this.opportunityName = '-';
            this.projectName = '-';
            this.towerName = '-';
            this.unitName = '-';
            this.floorNo = '-';
            this.totalCarpetArea = '-';
            this.bookingDate = System.today();
            this.modeOfFunding = '-';
            this.anyOtherOffers = '-';
            this.remarks = '-';
            this.isLoanSanctioned = 'No';
            this.loanSanctionedBankName = '-';
            this.loanSactionedPreferredBankName = '-';
            this.sanctionedAmount = 0.0;
            this.ownContributionAmount = 0.0;
            this.bookingSource = '-';
            this.bookingSubsource = '-';
        }
    }


    // Get Tenant Account 
    @AuraEnabled
    public static Quotation__c getTenantAccount(String quotationID){
        try {
            Quotation__c tenantAccount = [SELECT Id, Name,
                                            Tenant_Account__c, Tenant_Account__r.Name, Tower__c, Tower__r.Name,
                                            Unit__c, Unit__r.Name, Unit__r.Floor__c, Unit__r.Total_carpet_Sq_Ft__c
                                          FROM Quotation__c 
                                          WHERE Id =:quotationID LIMIT 1];
            return tenantAccount;
        } catch (Exception e) {
            throw new CustomException('Error in getting quotation with ID : ' + quotationID, e);
        }
    }

    // Get Quotation Type : Tenant Based | Opportunity Based
    @AuraEnabled
    public static String getQuotationType(String quotationID){
        try {
            Quotation__c quotation = [SELECT Id, Quotation_Type__c
                                      FROM Quotation__c
                                      WHERE Id = :quotationID LIMIT 1];
            return quotation.Quotation_Type__c;
        } catch (Exception e) {
            throw new CustomException('Error in getting quotation with ID : ' + quotationID, e);
        }
    }


    // Returns the Booking data
    @AuraEnabled(cacheable=true)
    public static BookingDetails getBookingDetails(){
        try {   
            return new BookingDetails();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Returns the Legal Entity Details
    @AuraEnabled(Cacheable=true)
    public static Legal_Entity__c getLegalEntity(String unitID){
        try {

            Boolean isValidUnitID = isValidRecordID(unitID);
            if(!isValidUnitID){
                throw new CustomException('Invalid Record ID for Unit : ' + unitID);
            }


            // Retrive Legal Entity details from Unit/Tower/Project 
            String legalEntityID = null;
            Legal_Entity__c legalEntity = null;
            Unit__c unit = [SELECT Id, Name, Legal_Entity__c, Tower__r.Legal_Entity__c,
                                Tower__r.Project__r.Legal_Entity__c 
                            FROM Unit__c 
                            WHERE Id = :unitID LIMIT 1];

            if(unit.Legal_Entity__c != null || unit.Tower__r.Legal_Entity__c != null ||
               unit.Tower__r.Project__r.Legal_Entity__c != null){

                legalEntityID = unit.Legal_Entity__c;
                if(legalEntityID == null){
                    legalEntityID = unit.Tower__r.Legal_Entity__c;
                }
                if(legalEntityID == null){
                    legalEntityID = unit.Tower__r.Project__r.Legal_Entity__c;
                }
            }

            if(legalEntityID == null){
                throw new CustomException('No Legal Entity maintained on Project/Tower/Unit');
            }


            // Retrive Legal Entity Details
            legalEntity = [SELECT Id, Name, Account_Name_Flat_Cost__c, Account_Name_Tax__c,
                                  Account_Number_Flat_Cost__c, Account_Number_Tax__c,
                                  Bank_Name_Flat_Cost__c, Bank_Name_Tax__c,
                                  Branch_Name_Flat_Cost__c, Branch_Name_Tax__c,
                                  IFSC_Code_Flat_Cost__c, IFSC_Code_Tax__c
                          FROM Legal_Entity__c
                          WHERE Id = :legalEntityID LIMIT 1];

            return legalEntity;
            
        } catch(QueryException e){
            throw new CustomException('Unable to get Charge details from Unit as no Unit found with provided unitID' + unitID, e);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    
    public class ApplicantDetailsWrapper{
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String salutation {get; set;}
        @AuraEnabled public String applicantNumber {get; set;}

        @AuraEnabled public String mobileNo {get; set;}
        @AuraEnabled public String email {get; set;}
        @AuraEnabled public String companyName {get; set;}
        @AuraEnabled public String designation {get; set;}
        @AuraEnabled public Date dateOfBirth {get; set;}
        @AuraEnabled public Date anniversaryDate {get; set;}
        @AuraEnabled public String aadharCardNo {get; set;}
        @AuraEnabled public String panCardNo {get; set;}
        @AuraEnabled public String typeOfApplicant {get; set;}
        @AuraEnabled public String residentialStatus {get; set;}
        @AuraEnabled public String nationality {get; set;}

        @AuraEnabled public String mailingStreet {get; set;}
        @AuraEnabled public String mailingCity {get; set;}
        @AuraEnabled public String mailingState {get; set;}
        @AuraEnabled public String mailingCountry {get; set;}
        @AuraEnabled public String mailingPincode {get; set;}

        @AuraEnabled public String permanentStreet {get; set;}
        @AuraEnabled public String permanentCity {get; set;}
        @AuraEnabled public String permanentState {get; set;}
        @AuraEnabled public String permanentCountry {get; set;}
        @AuraEnabled public String permanentPincode {get; set;}

        @AuraEnabled public Boolean isPermanentAddressSameAsMailing {get; set;}
        @AuraEnabled public String documentUploadRequired {get; set;}

        public ApplicantDetailsWrapper(){
            this.name = '-';
            this.salutation = '-';
            this.applicantNumber = '-';
            this.mobileNo = '-';
            this.email = '-';
            this.companyName = '-';
            this.designation = '-';
            this.dateOfBirth = System.today();
            this.anniversaryDate = System.today();
            this.aadharCardNo = '-';
            this.panCardNo = '-';
            this.typeOfApplicant = '-';
            this.residentialStatus = '-';
            this.nationality = '-';
            this.mailingStreet = '-';
            this.mailingCity = '-';
            this.mailingState = '-';
            this.mailingCountry = '-';
            this.mailingPincode = '-';
            this.permanentStreet = '-';
            this.permanentCity = '-';
            this.permanentState = '-';
            this.permanentCountry = '-';
            this.permanentPincode = '-';
            this.isPermanentAddressSameAsMailing = false;
            this.documentUploadRequired = '-';
        }
    }

    @AuraEnabled(cacheable=true)
    public static ApplicantDetailsWrapper getApplicantWrapper(){
        return new ApplicantDetailsWrapper();
    }
    

    public Quotation__c q {get;set;}
    public Map<String, Object> data { get; set; }
    
    @AuraEnabled
    public static Quotation__c getQuotationDetails(String qId){
        List<Quotation__c> qList = new List<Quotation__c>();
         String[] types = new String[]{'Quotation__c'};
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
        System.debug('qid : ' + qId);
        String soqlQuery = 'Select ' + queryFields  + ', Opportunity__r.Name, Project__r.Name, Tower__r.Name, Opportunity__r.Walk_In_Source__c, Opportunity__r.Walk_In_Sub_Source__c, Opportunity__r.OwnerId, Unit__r.Name, Unit__r.Floor__c, Unit__r.Total_carpet_Sq_Ft__c, Payment_Scheme__r.Name, Booking__r.Agreement_Value__c, Unit__r.Saleable_Area__c, Tenant_Account__r.Name, Project__r.TDS_Percentage__c,  Project__r.TDS_Threshold__c,  from Quotation__c Where Id = :qId';
        system.debug(soqlQuery);
        qList = Database.query(soqlQuery);
        
        if(!qList.isEmpty() && qList != null){
            return qList[0];
        }else{
            return null;
        }
    }
    
    @AuraEnabled(Cacheable=false)
    public static List<Legal_Entity__c> getLegalEntityDetails(String qId){
        List<Legal_Entity__c> legalEntities = new List<Legal_Entity__c>();
        List<Quotation__c> qList = [Select Id, Name, Unit__r.Name, Project__c, Tower__c, Tower__r.Name, Project__r.Name, Unit__r.Floor__c, Unit__r.Configuration_Type__c, Unit__r.Total_Carpet_Sq_Ft__c from Quotation__c where Id = :qId];
        if (!qList.isEmpty() && qList != null) {
            for (Quotation__c quote : qList) {
                // Legal_Entity__c le = EX_InventoryPriceManagementServices.getLegalEntityDetails(quote.Unit__r.id, quote.Tower__r.id, quote.Project__r.id);
                // if (le != null) {
                //     legalEntities.add(le);
                // }
            }
        }
        return legalEntities;
    }
    
    @AuraEnabled(cacheable=false)
    public static BookWrapper getBookingWrapper(String oppId){
        Opportunity opp = [Select Id, Project__c from Opportunity Where Id =: oppId];
        BookWrapper bk = new BookWrapper();
        bk.bk.Booking_Date__c = System.today();
        // if(opp.Project__r.CRM_Head__c != null){
        //    bk.bk.CRM_Head__c = opp.Project__r.CRM_Head__c;
        //    bk.bk.Level_1_Approver__c = opp.Project__r.CRM_Head__c;
        //    if(opp.Project__r.CRM_Head__r.ManagerId != null) 
        //    bk.bk.Level_2_Approver__c = opp.Project__r.CRM_Head__r.ManagerId;  
        // }
        
        return bk;
    }
    

    public class BookWrapper{
        @AuraEnabled 
        public Booking__c bk { get; set; }
        
        public BookWrapper(){
            bk = new Booking__c();
        }
    }    
    
    @AuraEnabled(cacheable=false)
    public static List<ReceiptWrapper> getReceipts() {
        List<ReceiptWrapper> rcList = new List<ReceiptWrapper>();
        Receipt__c rc = new Receipt__c();
        rcList.add(new ReceiptWrapper(rc));
        return rcList;
    }
    
    public class ReceiptWrapper{
        @AuraEnabled public Receipt__c rc;
        
        public ReceiptWrapper(Receipt__c rc) {
            this.rc = rc;
        }
        public ReceiptWrapper(){
            
        }
    } 
    
    
    @AuraEnabled(cacheable=false)
    public static List<ApplicantWrapper> ApplicantdocumentDetails(String fieldValue, String nationality, String oppId, String tabKey) {
        System.debug('tabKey: '+tabKey);
        System.debug('oppId: '+oppId);
        
        List<ApplicantWrapper> appList = new List<ApplicantWrapper>();
        List<Opportunity> opp = new List<Opportunity>();
        Applicant__c ap = new Applicant__c();
        if(oppId != null)
        {
            opp = [Select Id, Name, Account.Name, Account.Salutation, Primary_Mobile__c, Primary_Email__c, Account.Designation__c,
                   OwnerId, Account.Company_Name__c, Account.Street_1__c, Account.Country_1__c, Account.PinCode_2__c, Account.State_1__c,
                   Account.BillingPostalCode, Account.BillingCountry, Account.BillingState,
                   Account.BillingCity,
                   Account.City_1__c, Account.Pincode_1__c from Opportunity where Id=: oppId];
            if(opp != null)
            {
                if(String.isNotBlank(tabKey) && tabKey.equalsIgnoreCase('Applicant 1'))
                {
                    ap.Applicant_Number__c = 'Primary Applicant';
                    if(opp[0].Name != null)
                        ap.Name = opp[0].Name;
                    if(opp[0].Primary_Mobile__c != null)
                        ap.Primary_Mobile__c = opp[0].Primary_Mobile__c;
                    if(opp[0].Primary_Email__c != null)
                        ap.Primary_Email__c = opp[0].Primary_Email__c; 
                    if(opp[0].Account.Designation__c != null)
                        ap.Designation__c = opp[0].Account.Designation__c; 
                    if(opp[0].Account.Company_Name__c != null)
                        ap.Company_Name__c = opp[0].Account.Company_Name__c;
                    if(opp[0].Account.Salutation != null)
                        ap.Applicant_Title__c = opp[0].Account.Salutation;
                    if(opp[0].Account.City_1__c != null)
                        ap.Permanent_City__c = opp[0].Account.City_1__c;
                    if(opp[0].Account.PinCode_1__c != null)
                        ap.Permanent_Pin_Code__c = opp[0].Account.PinCode_1__c;
                     if(opp[0].Account.Country_1__c != null)
                        ap.Permanent_Country__c = opp[0].Account.Country_1__c;
                    if(opp[0].Account.State_1__c != null)
                        ap.Permanent_State__c = opp[0].Account.State_1__c;
                    if(opp[0].Account.Street_1__c != null)
                        ap.Permanent_Address__c = opp[0].Account.Street_1__c;
                    
                }
            }
        }
        appList.add(new ApplicantWrapper(ap));
        
        if(String.isNotBlank(fieldValue) && !(fieldValue.equalsIgnoreCase('No')) && String.isNotBlank(nationality) && nationality.equalsIgnoreCase('Indian')){            
            nationality = '%' + nationality + '%';
            List<Applicant_Document__c> documents = [SELECT Name, Document_Upload_Required__c, Nationality__c FROM Applicant_Document__c Where Document_Upload_Required__c =: fieldValue AND Nationality__c LIKE :nationality]; 
            for (Applicant_Document__c document : documents) {
                ApplicantWrapper wrapper = new ApplicantWrapper(document);
                wrapper.fileUploader = '';
                wrapper.fileName = document.Name;
                appList.add(wrapper);
            }
        } else if(String.isNotBlank(fieldValue) && !(fieldValue.equalsIgnoreCase('No')) && String.isNotBlank(nationality) && nationality.equalsIgnoreCase('NRI')){            
            nationality = '%' + nationality + '%';
            List<Applicant_Document__c> documents = [SELECT Name, Document_Upload_Required__c, Nationality__c FROM Applicant_Document__c Where Document_Upload_Required__c =: fieldValue AND Nationality__c LIKE: nationality]; 
            for (Applicant_Document__c document : documents) {
                ApplicantWrapper wrapper = new ApplicantWrapper(document);
                wrapper.fileUploader = '';
                wrapper.fileName = document.Name;
                appList.add(wrapper);
            }
        }else{
            if(String.isNotBlank(fieldValue) && (fieldValue.equalsIgnoreCase('No'))){            
                List<Applicant_Document__c> documents = [SELECT Name, Document_Upload_Required__c FROM Applicant_Document__c Where Document_Upload_Required__c =: fieldValue]; 
                System.debug('documents: ' + documents);
                for (Applicant_Document__c document : documents) {
                    ApplicantWrapper wrapper = new ApplicantWrapper(document);
                    wrapper.fileUploader = '';
                    wrapper.fileName = document.Name;
                    appList.add(wrapper);
                }
            }
        }
        System.debug('ApplicantDocumentlist: ' + appList);
        return appList;
    }
    

    
    public class ApplicantWrapper {
        @AuraEnabled public Applicant__c ap { get; set; }
        @AuraEnabled public Applicant_Document__c documents { get; set; }
        @AuraEnabled public String fileUploader { get; set; }
        @AuraEnabled public String fileName { get; set; }        
        
        public ApplicantWrapper(Applicant_Document__c documents) {
            this.documents = documents;
            this.fileUploader = '';
            this.fileName = '';
        }
        public ApplicantWrapper(Applicant__c ap) {
            this.ap = ap;
            this.documents = null;
            this.fileUploader = '';
            this.fileName = '';
        }
    }
    
    public class ApplicantDocumentWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public String docupload;
        @AuraEnabled public String fileUploader;
        @AuraEnabled public String fileName;
        
        public ApplicantDocumentWrapper(Applicant_Document__c document) {
            this.name = document.Name;
            this.docupload = document.Document_Upload_Required__c;
            this.fileUploader = '';
            this.fileName = '';
        }
    }
    
    
    @AuraEnabled
    public static Id createBookingRecord(BookWrapper bkWrapper, String applicantData, Quotation__c quotationDetails,
                                         String receiptData, Legal_Entity__c bookingAccount, BookingDetails bookingDetails){
        System.debug('bookingAccount: '+bookingAccount);
        System.debug('quotationDetails: '+quotationDetails);
        Decimal agreementValue = 0;
        Decimal agreementValueTax = 0;
        Decimal SDRValue = 0;
        Decimal SDRTax = 0;
        Decimal registrationValue = 0;
        Decimal registrationValueTax = 0;
        Decimal stampDutyValueTax = 0;
        Decimal stampDutyValue = 0;
        
        List<Object> applicantDataList = (List<Object>) JSON.deserializeUntyped(applicantData); 
        List<Object> receiptList = (List<Object>) JSON.deserializeUntyped(receiptData);
        List<Receipt__c> InsertReceipt = new List<Receipt__c>();
        List<Document__c> documentsToInsert = new List<Document__c>();
        List<Applicant__c> applicantRecords = new List<Applicant__c>();
        Quotation__c quotation = quotationDetails;
        system.debug('quotation is::'+quotation);
        quotation = getQuotationDetails(quotation.Id);
        system.debug('quotation is::'+quotation);
        System.debug('bkWrapper: '+bkWrapper);
        system.debug('quotation: '+quotation);
        system.debug('applicantData: '+applicantData);
        
        
        Booking__c booking = new Booking__c();
        if (quotation.Id != null) {
            booking.Quotation__c = quotation.Id;
        }
        if (quotation.Project__c != null) {
            booking.Project__c = quotation.Project__c;
        }
        if (quotation.Tower__c != null) {
            booking.Tower__c = quotation.Tower__c;
        }
        if (quotation.Unit__c != null) {
            booking.Unit__c = quotation.Unit__c;
        }
        if (quotation.Opportunity__c != null) {
            booking.Opportunity__c = quotation.Opportunity__c;
            booking.Booking_Type__c = 'Opportunity Based';        
        }
        
        if (bkWrapper.bk.Any_Other_Offers__c != null) {
            booking.Any_Other_Offers__c = bkWrapper.bk.Any_Other_Offers__c;
        }
        if (bkWrapper.bk.Mode_of_Funding__c != null) {
            booking.Mode_of_Funding__c = bkWrapper.bk.Mode_of_Funding__c;
        }
        booking.Booking_Date__c = System.today();

        // Extra Details from BookingDetailsWrapper
        if(bookingDetails.remarks != null && !String.isEmpty(bookingDetails.remarks)){
            booking.Remarks__c = bookingDetails.remarks;
        }
        if(quotation.Unit__r.Floor__c != null){
            booking.Floor__c = quotation.Unit__r.Floor__c;
        }
        if(quotation.Tenant_Account__c != null){
            booking.Tenant_Account__c = quotation.Tenant_Account__c;
            booking.Booking_Type__c = 'Tenant Based';
        }        


        // Loan Sanctioned Details
        if(bookingDetails.loanSactionedPreferredBankName != null) {
            booking.Loan_Sanctioned_Preferred_Bank_Name__c = bookingDetails.loanSactionedPreferredBankName;
        }
        if(bookingDetails.ownContributionAmount != null) {
            booking.Own_Contribution_Amount__c	 = bookingDetails.ownContributionAmount;
            booking.Loan_Sanction_Amount__c	= quotation.Modified_AV_Value__c - bookingDetails.ownContributionAmount;
        }
        if(bookingDetails.modeOfFunding != null) {
            booking.Mode_Of_Funding__c	 = bookingDetails.modeOfFunding;
        }

        // Booking Source Details
        if(bookingDetails.bookingSource != null) {
            booking.Booking_Source__c = bookingDetails.bookingSource;
        }
        if(bookingDetails.bookingSubsource != null) {
            booking.Booking_Sub_Source__c = bookingDetails.bookingSubsource;
        }
        if(bookingDetails.channelPartnerName != null) {
            booking.Channel_Partner_Name__c = bookingDetails.channelPartnerName;
        }
        if(bookingDetails.channelPartnerMobile != null) {
            booking.Channel_Partner_Mobile__c = bookingDetails.channelPartnerMobile;
        }
        if(bookingDetails.channelPartnerEmail != null) {
            booking.Channel_Partner_Email__c = bookingDetails.channelPartnerEmail;
        }
        if(bookingDetails.channelPartnerReraNo != null) {
            booking.Channel_Partner_RERA_No__c	 = bookingDetails.channelPartnerReraNo;
        }
        if(bookingDetails.channelPartnerPOC != null) {
            booking.Channel_Partner_POC__c	 = bookingDetails.channelPartnerPOC;
        }



        
        booking.Agreement_Value__c = quotation.Modified_AV_Value__c;
        booking.Agreement_Value_Tax__c = quotation.Modified_GST_Charges__c;
        booking.Stamp_Duty_Value__c	 = quotation.Modified_Stamp_Duty_Charges__c	;
        booking.Registration_Charges__c = quotation.Registration_Charges__c;
        booking.Other_Charges__c = quotation.Modified_Other_Charges_Including_Tax__c;
        booking.All_In_Value__c = quotation.Modified_All_in_Price__c;
        booking.TDS_Expected_Amount__c = quotation.Modified_AV_Value__c >= quotation.Project__r.TDS_Threshold__c ? quotation.Modified_AV_Value__c*quotation.Project__r.TDS_Percentage__c: 0;

        booking.Booking_Stage__c = 'Booking Confirmed';
        
        if(bookingAccount != null){
            booking.Account_Name_Flat_Cost__c = bookingAccount.Account_Name_Flat_Cost__c;
            booking.Account_Name_Tax__c = bookingAccount.Account_Name_Tax__c;
            booking.Account_Number_Flat_Cost__c = bookingAccount.Account_Number_Flat_Cost__c;
            booking.Account_Number_Tax__c = bookingAccount.Account_Number_Tax__c;
            booking.Bank_Name_Flat_Cost__c = bookingAccount.Bank_Name_Flat_Cost__c;
            booking.Branch_Name_Flat_Cost__c = bookingAccount.Branch_Name_Flat_Cost__c;
            booking.Branch_Name_Tax__c = bookingAccount.Branch_Name_Tax__c;
            booking.Bank_Name_Tax__c = bookingAccount.Bank_Name_Tax__c;
            booking.IFSC_Code_Flat_Cost__c = bookingAccount.IFSC_Code_Flat_Cost__c;
            booking.IFSC_Code_Tax__c = bookingAccount.IFSC_Code_Tax__c;
        }
        try {
            insert booking;
            System.debug('Booking record inserted successfully : ' + booking.Id);
        }catch(Exception ex) {
            System.debug('An error occurred: ' + ex.getMessage());
        }
        
        
        //update Opportunity after Booking creation
        List<Opportunity> oppList = new List<Opportunity>();
        if (String.isNotBlank(quotation.Opportunity__c)) {
            oppList = [SELECT StageName, /*CP_Project__c,*/ Sourcing_Manager__c, Sub_Stage__c, Sub_Stage_Reason__c,  Booking__c,
                              OwnerId, /*Channel_Partner__c,*/ Walk_In_Source__c, Walk_In_Sub_Source__c, Referrer_Name__c, Presales_Manager__c,
                              Campaign__c
                       FROM Opportunity 
                       WHERE Id = :quotation.Opportunity__c];
        }
        System.debug('oppList'+ oppList);
        
        if (oppList != null && !oppList.isEmpty()) {
            if (booking.Id != null) {
                oppList[0].Booking__c = booking.Id;
                oppList[0].StageName = 'Booked';
                oppList[0].Sub_Stage__c = '';
                oppList[0].Sub_Stage_Reason__c = '';
            }
            
            /*if (oppList[0].Channel_Partner__c != null) {
                booking.Channel_Partner__c = oppList[0].Channel_Partner__c;
            }
            if (oppList[0].CP_Project__c != null) {
                booking.CP_Project__c = oppList[0].CP_Project__c;
            }*/
            if (oppList[0].Referrer_Name__c != null) {
                booking.Referrer_Name__c = oppList[0].Referrer_Name__c;
            }



            // Managerial Details
            if (oppList[0].Sourcing_Manager__c != null) {
                booking.Sourcing_Manager__c = oppList[0].Sourcing_Manager__c;
            }
            if (oppList[0].OwnerId != null) {
                booking.Sales_Manager__c = oppList[0].OwnerId;
            }
            if (oppList[0].Presales_Manager__c != null) {
                booking.Presales_Manager__c	 = oppList[0].Presales_Manager__c;
            }

            
                            
            if (oppList[0].Walk_In_Source__c != null) {
                booking.Booking_Source__c = oppList[0].Walk_In_Source__c;
            }
            if (oppList[0].Walk_In_Sub_Source__c != null) {
                booking.Booking_Sub_Source__c = oppList[0].Walk_In_Sub_Source__c;
            }
            if (oppList[0].Campaign__c != null) {
                booking.Campaign__c = oppList[0].Campaign__c;
            }
        }
        
        try {
            if (oppList != null && !oppList.isEmpty()) {
                update oppList;
                //updateCPProjectDetails(booking.CP_Project__c, booking);
            }
        } catch (Exception ex) {
            System.debug('An error occurred: ' + ex.getMessage());
        }
        
        
        if (String.isNotBlank(quotation.Id)) {
            Quotation__c qList = [SELECT Booking__c FROM Quotation__c WHERE ID = :quotation.Id];
            if (qList != null) {
                qList.Booking__c = booking.Id;
                update qList;
            }
        }
        
        if (String.isNotBlank(quotation.Unit__c)) {
            Unit__c uniList = [SELECT Sale_Status__c FROM Unit__c WHERE ID = :quotation.Unit__c];
            
            if (uniList != null) {
                if (String.isNotBlank(uniList.Sale_Status__c)) {
                    uniList.Sale_Status__c = 'Booked';
                }
                
                if(booking != null && booking.Id != null){
                    uniList.Booking__c = booking.Id;  
                }
                if (oppList != null && !oppList.isEmpty()) {
                    uniList.Opportunity__c = oppList[0].Id;
                }
                update uniList;
            }
        }
        
        if(!receiptList.isEmpty() && receiptList!=null){
            for (Object dataObj : receiptList) {
                Map<String, Object> data = (Map<String, Object>) dataObj;
                Map<String, Object> apData = (Map<String, Object>) data.get('rc');
                
                if(!apData.isEmpty() && apData !=null && apData.containsKey('Receipt_Type__c') && apData.get('Receipt_Type__c') != null){
                    Receipt__c Receipt = new Receipt__c();
                    Receipt.Mode_of_Payment__c = (String) apData.get('Mode_of_Payment__c');
                    if(apData.get('Is_Token_Amount_Received__c') != null){
                        Receipt.Is_Token_Amount_Received__c = (Boolean) apData.get('Is_Token_Amount_Received__c');
                    }  
                    Receipt.Receipt_Type__c = (String) apData.get('Receipt_Type__c');
                    // Receipt.Receipt_Status__c = (String) apData.get('Receipt_Status__c');
                    String dateString = (String)apData.get('Receipt_Date__c');
                    if (dateString != null) {
                        Date receiptdate;
                        receiptdate = Date.valueOf(dateString);
                        Receipt.Receipt_Date__c = receiptdate;
                    }    
                    if(apData.get('Amount__c') != null){
                        Receipt.Amount__c = Decimal.valueOf((String) apData.get('Amount__c'));    
                    }
                    Receipt.Transaction_ID__c = (String) apData.get('Transaction_ID__c');
                    Receipt.Booking__c  = booking.id;
                    Receipt.Payment_Status__c = (String) apData.get('Payment_Status__c');
                    Receipt.Bank_Name__c = (String) apData.get('Bank_Name__c');
                    String InstrumentdateString = (String)apData.get('Instrument_Date__c');
                    Receipt.Payment_Type__c = (String) apData.get('Payment_Type__c');
                    if (InstrumentdateString != null) {
                        Date Instrumentdate;
                        Instrumentdate = Date.valueOf(InstrumentdateString);
                        Receipt.Instrument_Date__c = Instrumentdate;
                    }    
                    InsertReceipt.add(Receipt);
                }    
            }
        }  
        try {
            insert InsertReceipt;
            System.debug('InsertReceipt: ' + InsertReceipt);
        } catch (DmlException e) {
            System.debug('An error occurred when inserting records: ' + e.getMessage());
        }
        
        
        if(!applicantDataList.isEmpty() && applicantDataList!=null){
            for (Object dataObj : applicantDataList) {
                Map<String, Object> getAllData = (Map<String, Object>) dataObj;
                system.debug('getAllData::' + getAllData);
                Map<String, Object> apData = (Map<String, Object>) getAllData.get('ap');
                List<Object> documentsList = (List<Object>) getAllData.get('documents');
                
                Applicant__c applicant = new Applicant__c();
               // Booking.Is_Send_For_Approval__c = true;
                if (apData.get('Name') != null) {
                    applicant.Name = (String) apData.get('Name');
                }
                if (apData.get('Applicant_Title__c') != null) {
                    applicant.Applicant_Title__c = (String) apData.get('Applicant_Title__c');
                }
                if (apData.get('Applicant_Number__c') != null) {
                    applicant.Applicant_Number__c = (String) apData.get('Applicant_Number__c');
                }
                if (apData.get('Type_Of_Applicant__c') != null) {
                    applicant.Type_Of_Applicant__c = (String) apData.get('Type_Of_Applicant__c');
                }
                if (apData.get('Permanent_Address__c') != null) {
                    applicant.Permanent_Address__c = (String) apData.get('Permanent_Address__c');
                }
                if (apData.get('Permanent_City__c') != null) {
                    applicant.Permanent_City__c = (String) apData.get('Permanent_City__c');
                }
                if (apData.get('Permanent_State__c') != null) {
                    applicant.Permanent_State__c = (String) apData.get('Permanent_State__c');
                }
                if (apData.get('Permanent_Country__c') != null) {
                    applicant.Permanent_Country__c = (String) apData.get('Permanent_Country__c');
                }
                if (apData.get('Permanent_Pin_Code__c') != null) {
                    applicant.Permanent_Pin_Code__c = (String) apData.get('Permanent_Pin_Code__c');
                }
                if (apData.get('Designation__c') != null) {
                    applicant.Designation__c = (String) apData.get('Designation__c');
                }
                if (apData.get('Document_Upload_Required__c') != null) {
                    applicant.Document_Upload_Required__c = (String) apData.get('Document_Upload_Required__c');
                }
                String anniversaryDate = (String)apData.get('Anniversary_Date__c');
                if(String.isNotBlank(anniversaryDate)){
                    applicant.Anniversary_Date__c = Date.valueof(anniversaryDate);
                }
                String dobString = (String)apData.get('DOB__c');
                if (String.isNotBlank(dobString)){
                    Date dobDate;
                    dobDate = Date.valueOf(dobString);
                    applicant.DOB__c = dobDate;
                } 
                if (apData.get('Residential_Status__c') != null) {
                    applicant.Residential_Status__c = (String) apData.get('Residential_Status__c');
                }
                if (apData.get('Primary_Email__c') != null) {
                    applicant.Primary_Email__c = (String) apData.get('Primary_Email__c');
                }
                if (apData.get('Primary_Mobile__c') != null) {
                    applicant.Primary_Mobile__c = (String) apData.get('Primary_Mobile__c');
                }
                if (apData.get('PAN_Number__c') != null) {
                    applicant.PAN_Number__c = (String) apData.get('PAN_Number__c');
                }
                if (apData.get('Aadhar_Number__c') != null) {
                    applicant.Aadhar_Number__c = (String) apData.get('Aadhar_Number__c');
                }
                if (apData.get('Nationality__c') != null) {
                    applicant.Nationality__c = (String) apData.get('Nationality__c');
                }
                if (apData.get('Occupation__c') != null) {
                    applicant.Occupation__c = (String) apData.get('Occupation__c');
                }
                if (apData.get('Relation_with_Primary_Applicant__c') != null) {
                    applicant.Relation_with_Primary_Applicant__c = (String) apData.get('Relation_with_Primary_Applicant__c');
                }
                if (apData.get('Local_Contact_Name__c') != null) {
                    applicant.Local_Contact_Name__c = (String) apData.get('Local_Contact_Name__c');
                }
                if (apData.get('Local_Contact_Number__c') != null) {
                    applicant.Local_Contact_Number__c = (String) apData.get('Local_Contact_Number__c');
                }
                if (booking.Id != null) {
                    applicant.Booking__c = booking.Id;   
                }
                if (apData.get('Company_Name__c') != null) {
                    applicant.Company_Name__c = (String) apData.get('Company_Name__c');
                }
                Boolean mailingAddressSameAsPermanentAddressStr = (Boolean) apData.get('Mailing_Address_Same_as_PermanentAddress__c');
                System.debug('mailingAddressSameAsPermanentAddressStr:'+mailingAddressSameAsPermanentAddressStr);
                //Boolean mailingAddressSameAsPermanentAddress;
                if (mailingAddressSameAsPermanentAddressStr != null && mailingAddressSameAsPermanentAddressStr) {
                    mailingAddressSameAsPermanentAddressStr = true;
                    System.debug('mailingAddressSameAsPermanentAddress'+mailingAddressSameAsPermanentAddressStr);
                } else {
                    mailingAddressSameAsPermanentAddressStr = false;
                }
                applicant.Mailing_Address_Same_as_PermanentAddress__c = mailingAddressSameAsPermanentAddressStr;
                if (apData.get('Mailing_Country__c') != null) {
                    applicant.Mailing_Country__c = (String) apData.get('Mailing_Country__c');
                }
                if (apData.get('Mailing_State__c') != null) {
                    applicant.Mailing_State__c = (String) apData.get('Mailing_State__c');
                }
                if (apData.get('Mailing_City__c') != null) {
                    applicant.Mailing_City__c = (String) apData.get('Mailing_City__c');
                }
                if (apData.get('Mailing_Pincode__c') != null) {
                    applicant.Mailing_Pincode__c = (String) apData.get('Mailing_Pincode__c');
                }
                if (apData.get('Mailing_Address__c') != null) {
                    applicant.Mailing_Address__c = (String) apData.get('Mailing_Address__c');
                }
                if (mailingAddressSameAsPermanentAddressStr == true) {
                    if (apData.get('Permanent_Address__c') != null) {
                        applicant.Mailing_Address__c = (String) apData.get('Permanent_Address__c');
                    }
                    if (apData.get('Permanent_City__c') != null) {
                        applicant.Mailing_City__c = (String) apData.get('Permanent_City__c');
                    }
                    if (apData.get('Permanent_State__c') != null) {
                        applicant.Mailing_State__c = (String) apData.get('Permanent_State__c');
                    }
                    if (apData.get('Permanent_Country__c') != null) {
                        applicant.Mailing_Country__c = (String) apData.get('Permanent_Country__c');
                    }
                    String mailingPincodeStr = '';
                    if (apData.get('Permanent_Pin_Code__c') != null) {
                        mailingPincodeStr = (String) apData.get('Permanent_Pin_Code__c');   
                    }
                    if (mailingPincodeStr != '') {
                        Integer mailingPincode = Integer.valueOf(mailingPincodeStr);
                        system.debug('mailingPincode: '  +mailingPincode);
                        applicant.Mailing_Pincode__c = mailingPincodeStr;
                    }
                }
                try{
                    insert applicant;
                }catch(exception e){
                    system.debug('Exception on insert applicant :'+ e.getMessage());
                }
                if(applicant.Applicant_Number__c != null && applicant.Applicant_Number__c == 'Primary Applicant'){
                   // booking.Aadhar_Number__c = applicant.Aadhar_Number__c;
                   // booking.PAN_Number__c = applicant.PAN_Number__c;
                    booking.Primary_Applicant_Title__c = applicant.Applicant_Title__c;
                    booking.Primary_Applicant_Name__c = applicant.Name;
                    booking.Primary_Applicant_Mobile__c = applicant.Primary_Mobile__c;
                    booking.Primary_Applicant_Email__c = applicant.Primary_Email__c;
                    if (!mailingAddressSameAsPermanentAddressStr) {
                        if (applicant.Mailing_Address__c == null) {
                            applicant.Mailing_Address__c = '';
                        }
                        if (applicant.Mailing_City__c == null) {
                            applicant.Mailing_City__c = '';
                        }
                        if (applicant.Mailing_State__c == null) {
                            applicant.Mailing_State__c = '';
                        }
                        if (applicant.Mailing_Country__c == null) {
                            applicant.Mailing_Country__c = 'India'; //if null then default
                        }
                        if (applicant.Mailing_Pincode__c == null) {
                            applicant.Mailing_Pincode__c = '';
                        }
                        
                        booking.Primary_Applicant_Address__c = applicant.Mailing_Address__c + ', ' +
                            applicant.Mailing_City__c + ', ' +
                            applicant.Mailing_State__c + ', ' +
                            applicant.Mailing_Country__c + ', - ' +
                            applicant.Mailing_Pincode__c;
                    } else {
                        if (applicant.Permanent_Address__c == null) {
                            applicant.Permanent_Address__c = '';
                        }
                        if (applicant.Permanent_City__c == null) {
                            applicant.Permanent_City__c = '';
                        }
                        if (applicant.Permanent_State__c == null) {
                            applicant.Permanent_State__c = '';
                        }
                        if (applicant.Permanent_Country__c == null) {
                            applicant.Permanent_Country__c = 'India'; //if null then default
                        }
                        if (applicant.Pin_Code__c == null) {
                            applicant.Pin_Code__c = '';
                        }
                        booking.Primary_Applicant_Address__c = 
                            applicant.Permanent_Address__c + ', ' +
                            applicant.Mailing_City__c + ', ' +
                            applicant.Mailing_State__c + ', ' +
                            applicant.Mailing_Country__c + ', - ' +
                            applicant.Mailing_Pincode__c;
                    }
                }
                try{
                    update booking; 
                    system.debug('Update:'+booking);
                }catch(exception e){
                    system.debug('Exception on update Booking :'+ e.getMessage());
                }
                
                if (documentsList != null && !documentsList.isEmpty()) {
                    for (Object document1 : documentsList) {
                        if (document1 instanceof Map<String, Object>) {
                            Map<String, Object> documentMap = (Map<String, Object>) document1;
                            system.debug('documentMap::' +documentMap);
                            Document__c document = new Document__c();
                            if (documentMap.get('Name') != null) {
                                document.Name__c = (String) documentMap.get('Name');
                            }
                            if (documentMap.get('Document_Upload_Required__c') != null) {
                                document.Document_Upload_Required__c = (String) documentMap.get('Document_Upload_Required__c');
                            }
                            if (documentMap.get('Type_Of_Applicant__c') != null) {
                                document.Type_Of_Applicant__c = (String) documentMap.get('Type_Of_Applicant__c');
                            }
                            if (documentMap.get('Residential_Status__c') != null) {
                                document.Residential_Status__c = (String) documentMap.get('Residential_Status__c');
                            }
                            string Isbase64 ='';
                            if(documentMap.containsKey('base64') && documentMap.get('base64')!= null){
                                Isbase64 = (string)documentMap.get('base64');
                            }
                            if(documentMap.get('type') != null){
                                System.debug('document type: '+documentMap.get('type'));
                                String docType = (String) documentMap.get('type');
                                if(docType.contains('Aadhar Card')){
                                    if(!String.isBlank(Isbase64)){
                                        document.uploaded__c =true;
                                    }
                                    document.Document_Type__c = 'Aadhar Card';
                                }else if(docType.contains('Pan Card')){
                                    if(!String.isBlank(Isbase64)){
                                        document.uploaded__c =true;
                                    }
                                    document.Document_Type__c = 'Pan Card';
                                }else if(docType.contains('Passport')){
                                    if(!String.isBlank(Isbase64)){
                                        document.uploaded__c =true;
                                    }
                                    document.Document_Type__c = 'Passport';
                                }
                            }
                            if(applicant.Id != null){
                                document.Applicant__c = applicant.Id;        
                            }
                            Id recordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('Applicant_Document').getRecordTypeId();
                            System.debug('recordTypeId: '+ recordTypeId);
                            if(recordTypeId != null){
                                document.RecordTypeId = recordTypeId;   
                            }
                            documentsToInsert.add(document);
                            insert document;
                            String base64 = (string) documentMap.get('base64');
                            String filename = (string) documentMap.get('filename');
                            
                            if (base64 != null && filename != null) {
                                ContentVersion cv = createContentVersion(base64, filename);
                                ContentDocumentLink cdl = createContentLink(cv.Id, document.Id);
                                if (cv == null || cdl == null) {
                                    return null;
                                }
                            }
                        }
                    }
                }
            }
        }    
        return booking.Id;
    }
    
    @testvisible
    private static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        try {
            insert cv;
            return cv;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }
    
    @testvisible
    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [ SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        
        
        ContentDistribution cd = new ContentDistribution();
        if(cdl.ContentDocumentId != null) {
            cd.Name = recordId;
            cd.ContentVersionId = contentVersionId;
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesLinkLatestVersion = true;
            cd.PreferencesNotifyOnVisit = false;
            cd.PreferencesPasswordRequired = false;
            cd.PreferencesAllowOriginalDownload = true;
            insert cd;   
            system.debug('cd: '+cd);
            
            cd = [SELECT Id, ContentDownloadUrl, DistributionPublicUrl FROM ContentDistribution WHERE Id =: cd.Id LIMIT 1];
            system.debug('DistributionPublicUrl: '+cd.DistributionPublicUrl);
        }
        try {
            insert cdl;
            
            List<Document__c> docList = new List<Document__c>();
            List<Document__c> updateDocList = new List<Document__c>();
            
            docList = [Select Id, Name, Document_Type__c, Document_View_Link__c from Document__c where Id =: recordId];
            for(Document__c doc: docList){
                if(String.isNotBlank(cd.DistributionPublicUrl)){
                    doc.Document_View_Link__c = cd.DistributionPublicUrl;
                    updateDocList.add(doc);
                }
            }
            if(!updateDocList.isEmpty()){
                update updateDocList;
            }
            
            
            return cdl;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
               
        
    } 


    // Returns list of other documents required 
    @AuraEnabled(cacheable=true)
    public static List<String> getBookingDocumentNames(){
        
        Map<String, Other_Documents__c> allOtherDocuments = Other_Documents__c.getAll();
        String BOOKING_DOCUMENT_IDENTIFIER = 'Booking Document';
        String REQUIRED_DOCUMENT_IDENTIFIER = 'Required_Documents__c';

        Boolean isBookingDocumentsMaintained = allOtherDocuments.containsKey(BOOKING_DOCUMENT_IDENTIFIER);
        Other_Documents__c bookingDocument;
        List<String> bookingDocumentNames;

        if(isBookingDocumentsMaintained){
            bookingDocument = allOtherDocuments.get(BOOKING_DOCUMENT_IDENTIFIER);
            String bookingDocumentNamesAsString = (String)bookingDocument.get(REQUIRED_DOCUMENT_IDENTIFIER);
            bookingDocumentNames = bookingDocumentNamesAsString.split(',');

            System.debug(bookingDocument);
            System.debug(bookingDocumentNamesAsString);
            System.debug(bookingDocumentNames);
        }
        return bookingDocumentNames;
    }

    // Save Booking Documents 
    @AuraEnabled
    public static Boolean createBookingDocuments(Map<String, String> bookingDocuments, String bookingID){

        String fileName = bookingDocuments.get('fileName');
        String base64 = bookingDocuments.get('base64');
        
        ContentVersion contentVersion = createContentVersion(base64, fileName);
        ContentDocumentLink contentDocumentLink = createContentLink(contentVersion.Id, bookingID);

        System.debug('contentVersion : ' + contentVersion);
        System.debug('contentDocumentLink : ' + contentDocumentLink);
        return true;
    }

    // ---- Utility Methods ----

    // Standard Validation to check RecordID 
    private static Boolean isValidRecordID(String recordID){

        if(recordID == null || String.isBlank(recordID) || String.isEmpty(recordID)){
            return false;
        }

        try {
            Id validRecordID = Id.valueOf(recordID);
            return true;
        } catch (StringException e){
            return false;
        } 
    }

    /*private static void updateCPProjectDetails(String CPProjectID, Booking__c booking){
        try {            
            if(CPProjectID != null && CPProjectID != ''){
                
                List<Booking__c> bookings = [SELECT Id FROM Booking__c 
                                            WHERE CP_Project__c =:CPProjectID];
                CP_Project__c cpProject = [SELECT Id, Name, Booking_Count__c, Last_Booking_Date__c
                                        FROM CP_Project__c WHERE Id=:CPProjectID];

                cpProject.Booking_Count__c = bookings.size();
                cpProject.Last_Booking_Date__c = booking.Booking_Date__c;
             
                UPDATE cpProject;
            }
        }
        catch (Exception e) {
            System.debug('Error occurred : ' + e);
        }
    } */   


    // ---- Custom Exception ----
    public class CustomException extends Exception {}
    
}