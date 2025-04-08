public class Ex_BookingPrintController {

    public List<BookingWrapper> bookingWrapperList {get;set;}

    public Ex_BookingPrintController() {

        // Get and Validate Booking ID
        String bookingID =  ApexPages.currentPage().getParameters().get('bookingID');
        if (bookingID == null) {
            bookingID = 'a0Z72000001pWTVEA2';
        }

        Boolean isValidBookingID = isValidRecordID(bookingID);
        if(!isValidBookingID){
            throw new CustomException('Provided Booking ID is incorrect !');
        }


        // Get Booking Details
        String bookingObject = 'Booking__c';
        String bookingFieldsCommaSeperated = getCommaSeparatedFieldNames(bookingObject);
        String bookingQuery = ' SELECT ' + bookingFieldsCommaSeperated  + 
                              ' FROM '   + bookingObject + 
                              ' WHERE ID = :bookingID' + 
                              ' LIMIT 1';
        Booking__c booking =  Database.query(bookingQuery);

        // Get Quotation Details
        String quotationID = booking.Quotation__c;
        String quotationFieldCommaSeperated = getCommaSeparatedFieldNames('Quotation__c');
        String quotationQuery = 'SELECT ' + quotationFieldCommaSeperated + ', ' +
                                ' Opportunity__r.Name' + 
                                ' FROM Quotation__c ' +
                                ' WHERE Id =:quotationID' +
                                ' LIMIT 1 ';
        Quotation__c quotation = Database.query(quotationQuery);

        // Get Unit Details 
        String unitObject = 'Unit__c';
        String unitFieldsCommaSeperated = getCommaSeparatedFieldNames(unitObject);
        String unitQuery = ' SELECT ' + unitFieldsCommaSeperated + ',' + 
                            ' Project__r.Name, Tower__r.Booking_Terms_and_Conditions__c, Tower__r.Name ' + 
                            ' FROM '   + unitObject + 
                            ' WHERE Booking__c = :bookingID' + 
                            ' LIMIT 1';
        Unit__c unit =  Database.query(unitQuery);


        // Get Applicant Details
        String applicantObject = 'Applicant__c';
        String applicantFieldsCommaSeperated = getCommaSeparatedFieldNames(applicantObject);
        String applicantQuery = ' SELECT ' + applicantFieldsCommaSeperated +
                                ' FROM '   + applicantObject + 
                                ' WHERE Booking__c = :bookingID';
        List<Applicant__c> applicants =  Database.query(applicantQuery);


        
        // ---- Prepare Applicant Details ----
        ApplicantDetails applicantDetails_raw = new ApplicantDetails();
        
        Applicant__c primaryApplicant = null;
        List<String> applicantNames = new List<String>();
        List<String> applicantPANs = new List<String>();
        List<String> applicantAadhars = new List<String>();
        List<String> applicantPhones = new List<String>();
        List<String> applicantEmails = new List<String>();
        List<String> applicantDOBs = new List<String>();
        List<String> applicantAnniversaryDates = new List<String>();
        List<List<String>> applicantDetailsRowWise = new List<List<String>>();

        
        for (Integer i = 0; i < applicants.size(); i++) {
            
            Applicant__c applicant = applicants[i];
            List<String> applicantDetailsRow = new List<String>();

            applicantDetailsRow.add(stringValueOf(applicant.Applicant_Number__c));
            applicantDetailsRow.add(stringValueOf(applicant.Relation_with_Primary_Applicant__c));
            applicantDetailsRow.add(formatDate(applicant.DOB__c));
            applicantDetailsRow.add(formatDate(applicant.Anniversary_Date__c));
            applicantDetailsRow.add(stringValueOf(applicant.PAN_Number__c));

            applicantNames.add(stringValueOf(applicant.Name));

            applicantDetailsRowWise.add(applicantDetailsRow);
            if(applicant.Applicant_Number__c == 'Primary Applicant'){
                primaryApplicant = applicant;
            }
        }


        applicantDetails_raw.applicantName = applicantNames.isEmpty() ? '-' : applicantNames[0];
        applicantDetails_raw.email = primaryApplicant.Primary_Email__c;
        applicantDetails_raw.mobile = primaryApplicant.Primary_Mobile__c;
        applicantDetails_raw.allApplicantNames = applicantNames;
        applicantDetails_raw.allApplicantPANs = applicantPANs;
        applicantDetails_raw.allApplicantAadhars = applicantAadhars;
        applicantDetails_raw.allApplicantPhones = applicantPhones;
        applicantDetails_raw.allApplicantEmails = applicantEmails;
        applicantDetails_raw.allApplicantDOBs = applicantDOBs;
        applicantDetails_raw.allApplicantAnniversaryDates = applicantAnniversaryDates;
        applicantDetails_raw.allApplicantDetailsRowWise = applicantDetailsRowWise;
        applicantDetails_raw.permanentAddress = primaryApplicant.Permanent_Address__c + ' ' + primaryApplicant.Permanent_City__c + ' ' +
                                                primaryApplicant.Permanent_State__c + ' ' + primaryApplicant.Permanent_Country__c + ' ' +
                                                primaryApplicant.Permanent_Pin_Code__c;
        applicantDetails_raw.presentAddress =   primaryApplicant.Mailing_Address__c + ' ' + primaryApplicant.Mailing_City__c + ' ' +
                                                primaryApplicant.Mailing_State__c + ' ' + primaryApplicant.Mailing_Country__c + ' ' +
                                                primaryApplicant.Mailing_Pincode__c;
        applicantDetails_raw.mailingSameAsPermanent = primaryApplicant.Mailing_Address_Same_as_PermanentAddress__c;
        applicantDetails_raw.occupation = primaryApplicant.Occupation__c;
        applicantDetails_raw.nationality = primaryApplicant.Nationality__c;
        applicantDetails_raw.isNonIndianResident = primaryApplicant.Nationality__c == 'NRI' || primaryApplicant.Nationality__c == 'PIO';
        applicantDetails_raw.localContactName = primaryApplicant.Local_Contact_Name__c;
        applicantDetails_raw.localContactNumber = primaryApplicant.Local_Contact_Number__c;
        applicantDetails_raw.coApplicantNames = applicantNames.isEmpty() ? applicantNames : removeFirst(applicantNames);
        applicantDetails_raw.isCoApplicantPresent = !applicantDetails_raw.coApplicantNames.isEmpty();



        // Unit Details
        UnitDetails unitDetails_raw = new UnitDetails();
        unitDetails_raw.projectName = unit.Project__r.Name;
        unitDetails_raw.towerName = unit.Tower__r.Name;
        unitDetails_raw.floorNo = String.valueOf(unit.Floor__c);
        unitDetails_raw.unitNo = unit.Name;
        unitDetails_raw.carpetAreaSqft = String.valueOf(unit.Total_carpet_Sq_Ft__c);
        unitDetails_raw.reraNo = '-';
        
        Decimal totalBaseCharge = quotation.Modified_AV_Value__c + quotation.Modified_Registration_Charges__c + quotation.Modified_Stamp_Duty_Charges__c + quotation.Modified_GST_Charges__c;
        unitDetails_raw.totalBaseCharges = formatCurrency(totalBaseCharge);
        unitDetails_raw.totalAgreementValue = formatCurrency(quotation.Modified_AV_Value__c);
        unitDetails_raw.totalAgreeementValueGST = formatCurrency(quotation.Modified_GST_Charges__c);
        unitDetails_raw.totalOtherCharges = formatCurrency(quotation.Modified_Other_Charges_Including_Tax__c);
        unitDetails_raw.registrationCharges = formatCurrency(quotation.Modified_Registration_Charges__c	);
        unitDetails_raw.stampDutyCharges = formatCurrency(quotation.Modified_Stamp_Duty_Charges__c);
        unitDetails_raw.totalUnitCost = formatCurrency(quotation.Modified_All_in_Price__c);
        unitDetails_raw.noOfParkings = String.valueOf(quotation.Car_Park_Required_Count__c);
        unitDetails_raw.totalCarParkAmount = formatCurrency(quotation.Car_Park_Amount__c);


        // Home loan
        HomeLoanAssement homeLoanAssement_raw = new HomeLoanAssement();
        homeLoanAssement_raw.isOptedForLoan = booking.Mode_Of_Funding__c == 'Loan';
        homeLoanAssement_raw.nameOfBank = booking.Loan_Sanctioned_Preferred_Bank_Name__c;
        homeLoanAssement_raw.bankOfficerName = booking.Name_of_Contact_Person_at_Bank_FI__c;
        homeLoanAssement_raw.bankOfficerContactNo = booking.Contact_No_of_Contact_Person_at_Bank_FI__c;
        homeLoanAssement_raw.ownContributionAmount = formatCurrency(booking.Own_Contribution_Amount__c);
        homeLoanAssement_raw.homeLoanAmount = formatCurrency(booking.Loan_Sanction_Amount__c);
    

        // Source Details 
        BookingSourceDetails bookingSourceDetails_raw = new BookingSourceDetails();
        bookingSourceDetails_raw.sourceOfBooking = booking.Booking_Source__c;
        bookingSourceDetails_raw.subSourceOfBooking = booking.Booking_Sub_Source__c;
        bookingSourceDetails_raw.isSourceChannelPartner = booking.Booking_Source__c == 'Channel Partner';


        ChannelPartnerDetails channelPartnerDetails_raw = new ChannelPartnerDetails();
        channelPartnerDetails_raw.channelPartnerName = booking.Channel_Partner_Name__c;
        channelPartnerDetails_raw.email = booking.Channel_Partner_Email__c;
        channelPartnerDetails_raw.phone1 = booking.Channel_Partner_Mobile__c;
        channelPartnerDetails_raw.channelPartnerPOC = booking.Channel_Partner_POC__c;
        channelPartnerDetails_raw.reraNo = booking.Channel_Partner_RERA_No__c;
        // channelPartnerDetails_raw.phone2 = booking.Channel_Partner_;
        // channelPartnerDetails_raw.panCardNo = booking.Channel_Partner_PAN;

        bookingSourceDetails_raw.channelPartnerDetails = channelPartnerDetails_raw;


        // Declaration and Terms and Conditions
        OtherDetails otherDetails_raw = new OtherDetails();
        otherDetails_raw.declarationDetails = 'Declaration details here';
        otherDetails_raw.termsAndConditions = unit.Tower__r.Booking_Terms_and_Conditions__c;
        otherDetails_raw.remarks = booking.Remarks__c;
        otherDetails_raw.bookingDate = formatDate(booking.CreatedDate);
        otherDetails_raw.formNo = booking.Name;


        // --- Update Details ----
        bookingWrapperList = new List<BookingWrapper>();

        BookingWrapper bookingWrapper_raw = new BookingWrapper();
        bookingWrapper_raw.applicantDetails = applicantDetails_raw;
        bookingWrapper_raw.unitDetails = unitDetails_raw;
        bookingWrapper_raw.homeLoanAssement = homeLoanAssement_raw;
        bookingWrapper_raw.bookingSourceDetails = bookingSourceDetails_raw;
        bookingWrapper_raw.otherDetails = otherDetails_raw;
        
        bookingWrapperList.add(bookingWrapper_raw);
        
    }

    
    public static String replacePTagsWithTD(String htmlContent) {
        if (String.isEmpty(htmlContent)) {
            return htmlContent;
        }
        // Replace opening <p> tags with <td>
        htmlContent = htmlContent.replaceAll('<p>', '<td>');
        // Replace closing </p> tags with </td>
        htmlContent = htmlContent.replaceAll('</p>', '</td>');
        return htmlContent;
    }


    // Get Comma Seperated Field Names
    private static String getCommaSeparatedFieldNames(String objectName) {

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            throw new IllegalArgumentException('Invalid object name: ' + objectName);
        }
        
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = objDescribe.fields.getMap();
        
        List<String> fieldNames = new List<String>(fieldsMap.keySet());

        return String.join(fieldNames, ', ');
    }

    // Format Currency
    private String formatCurrency(Decimal amt) {

        if(amt == null || amt == 0.0){
            return '0.00';
        }

        String formattedAmount = '';
        Decimal tempAmt = amt.setscale(2,RoundingMode.HALF_UP);
        String stringAmt = tempAmt.toPlainString();
        String decimalPart;
        List<String> tempStr = new List<String>();
        if(String.isNotBlank(stringAmt)) {
            tempStr = stringAmt.split('\\.');
            if(tempStr != null && tempStr.size() == 2) {
                decimalPart = tempStr[1];
            }
        }
        formattedAmount = (tempAmt.format().contains('.')?tempAmt.format():(tempAmt.format()+'.'+decimalPart));
        return formattedAmount;
    }  

    // Format Date
    private String formatDate(Datetime datetimeValue) {
        if (datetimeValue != null) {
            return DateTime.valueOf(datetimeValue).format('dd/MM/yyyy');
        }
        return '';
    }

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

    // Get String value
    private static String stringValueOf(String input){
        return input != null && input != '' ? input : '-';
    }

    // Remove first element from list
    public static List<String> removeFirst(List<String> input){
        List<String> output = input.clone();
        output.remove(0);

        
        return output;
    }

// --- Custom Exception ---
public class CustomException extends Exception {}

// --- All Booking Details ---
public class BookingWrapper{
    public ApplicantDetails applicantDetails {get; set;}
    public UnitDetails unitDetails {get; set;}
    public PaymentDetails paymentDetails {get; set;}
    public HomeLoanAssement homeLoanAssement {get; set;}
    public BookingSourceDetails bookingSourceDetails {get; set;}
    public DocumentList documentList {get; set;}
    public OtherDetails otherDetails {get; set;}
}

public class ApplicantDetails{
    public String applicantName {get;set;}
    public String presentAddress {get;set;}
    public String permanentAddress {get;set;}
    public String email {get;set;}
    public String mobile {get;set;}
    public Boolean mailingSameAsPermanent {get;set;}
    public String occupation {get;set;}
    public String nationality {get;set;}
    public Boolean isNonIndianResident {get;set;}
    public String localContactName {get;set;}
    public String localContactNumber {get;set;}

            
    public Boolean isCoApplicantPresent {get;set;}
    public List<String> coApplicantNames {get;set;}

    public List<String> allApplicantNames {get;set;}
    public List<String> allApplicantPANs {get;set;}
    public List<String> allApplicantAadhars {get;set;}
    public List<String> allApplicantPhones {get;set;}
    public List<String> allApplicantEmails {get;set;}
    public List<String> allApplicantDOBs {get;set;}
    public List<String> allApplicantAnniversaryDates {get;set;}
    public List<List<String>> allApplicantDetailsRowWise {get;set;}
}

public class UnitDetails{
    public String projectName {get;set;}
    public String towerName {get;set;}
    public String floorNo {get;set;}
    public String unitNo {get;set;}
    public String carpetAreaSqft {get;set;}
    public String reraNo {get;set;}
    public String totalBaseCharges {get;set;}
    public String totalAgreementValue {get;set;}
    public String totalAgreeementValueGST {get;set;}
    public String totalOtherCharges {get;set;}
    public String totalCarParkAmount {get;set;}
    public String registrationCharges {get;set;}
    public String stampDutyCharges {get;set;}
    public String totalUnitCost {get;set;}
    public String noOfParkings {get;set;}
}

public class PaymentDetails{
    public Boolean isPaymentDetailsFilled {get;set;}
    public String paymentMode {get;set;}
    public Boolean isTokenAmount {get;set;}
    public String paymentType {get;set;}
    public String receiptType {get;set;}
    public String paymentStatus {get;set;}
    public String bankName {get;set;}
    public String receiptDate {get;set;}
    public String instrumentDate {get;set;}
    public String transactionID {get;set;}
    public String amount {get;set;}
}

public class HomeLoanAssement{
    public Boolean isOptedForLoan {get;set;}
    public String nameOfBank {get;set;}
    public String bankOfficerName {get;set;}
    public String bankOfficerContactNo {get;set;}
    public String ownContributionAmount {get;set;}
    public String homeLoanAmount {get;set;}
}   

public class ChannelPartnerDetails{
    public String channelPartnerName {get;set;}
    public String channelPartnerPOC {get;set;}
    public String panCardNo {get;set;}
    public String reraNo {get;set;}
    public String email {get;set;}
    public String phone1 {get;set;}
    public String phone2 {get;set;}
}

public class BookingSourceDetails{
    public String sourceOfBooking {get;set;}
    public String subSourceOfBooking {get;set;}
    public Boolean isSourceChannelPartner {get;set;}

    public ChannelPartnerDetails channelPartnerDetails {get;set;}
}

public class DocumentList{
    public List<String> documentList {get;set;}
    public Map<String, Boolean> documentsStatus {get;set;}
}

public class OtherDetails{
    public String termsAndConditions {get;set;}
    public String declarationDetails {get;set;}
    public String remarks {get;set;}
    public String bookingDate {get;set;}
    public String formNo {get;set;}
}

}