import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getQuotationDetails from '@salesforce/apex/Ex_BookingFormController.getQuotationDetails';
import getBookingWrapper from '@salesforce/apex/Ex_BookingFormController.getBookingWrapper';
import getBookingDocumentNames from '@salesforce/apex/Ex_BookingFormController.getBookingDocumentNames'
import ApplicantdocumentDetails from '@salesforce/apex/Ex_BookingFormController.ApplicantdocumentDetails';
import createBookingRecord from '@salesforce/apex/Ex_BookingFormController.createBookingRecord';
import createBookingDocuments from '@salesforce/apex/Ex_BookingFormController.createBookingDocuments';
import getReceipts from '@salesforce/apex/Ex_BookingFormController.getReceipts';

import getLegalEntity from '@salesforce/apex/Ex_BookingFormController.getLegalEntity';
import getBookingDetails from '@salesforce/apex/Ex_BookingFormController.getBookingDetails';
import getApplicantWrapper from '@salesforce/apex/Ex_BookingFormController.getApplicantWrapper';

import APPLICANT_OBJECT from '@salesforce/schema/Applicant__c';
import APPLICANT_NUMBER_FIELD from "@salesforce/schema/Applicant__c.Applicant_Number__c";


export default class Ex_BookingForm extends LightningElement {
    @track getReceiptData = [];

    @api uId;
    @api oppId;
    @api qId;
    @track isSpinner = false;
    @track quote;
    @track showToast = false;
    @track toastMessage = '';
    @track toastVariant = ''; // success, warning, error
    @track showBankDetails = false;
    @track showLoanType = false;

    @track bkWrapper = { bk: {} };
    @track getBookingWrapperList = [];

    @track rcWrapper = { rc: {} };
    @track getReceiptWrapper = [];

    showPINMsg = '';
    showErrorMailingPIN = '';
    showMailingPINMsg = '';

    @track getApplicantData = [];
    @track applicantDocuments = [];
    @api activeTabValue = 'Applicant 1'; // Default value
    @track applicantCounter = 1;
    @track documentsArray = [];
    @track isdocumentRequired = true;

    
    // Added Later

    @track otherBookingDocumentNames = {};
    @track applicantWrapper = null;
    @track applicantNumber_OPTIONS = null;

    @track legalEntity = null;
    @track bookingDetails = null;
    @track applicantDetails = null;


    connectedCallback() {
        const urlSearchParams = new URLSearchParams(window.location.search);
        this.qId = urlSearchParams.get("recordId");
        console.log('this.qId is::'+this.qId);
        
        this.getQuotationDetailsCall();
        this.getApplicantDoc();
        this.getReceiptWrapperMethod();

        //this.showCustomToast('success', 'This is a success message!', 5000000); // Shows for 5 seconds\
        // if(this.isLoaded) return;
        // const STYLE = document.createElement("style");
        // STYLE.innerText = `.uiModal--medium .modal-container, .slds-modal__container{
        //     width: 95vw !important;
        //     height: 100vh !important;
        //     padding : 40px 20px 20px 20px !important;
        //     max-width : 100vw;
        //     min-width : 480px;
        //     max-height: 100vh;
        //     min-height: 480px;
        // }`;
        // this.template.querySelector('lightning-card').appendChild(STYLE);
        // this.isLoaded = true;
    }

    /* 
     * --- Returns Legal Entity Data ---
    */
    @wire(getLegalEntity, { unitID : "$uId" })
    retrieveLegalEntity({error, data}){
        if(data){
            console.log(JSON.stringify(data));
            this.legalEntity = data;   
        }
        if(error){
            console.log('Error while retriving the Legal Entity Data' + JSON.stringify(error));
        }
    }
    get getLegalEntityData(){
            var response = {
                isEmpty : this.legalEntity == null || this.legalEntity == undefined,
                data : this.legalEntity
            }
            return response;
    }


    /*
     * --- Get Booking Details ---
    */
   @wire(getBookingDetails)
   handleBookingDetails({error, data}){
        if(data){
            this.bookingDetails = data;
        }
        if(error){
            console.log('Error in getting booking details', JSON.stringify(error));
        }
   }

   get getBookingDetails(){
        var response = {
            isEmpty : this.bookingDetails == null || this.bookingDetails == undefined,
            data : this.bookingDetails
        }
        return response;
   }
   
   get isLoanSantionedStatusYes(){
        return this.bookingDetails?.isLoanSanctioned === 'Yes';
   }
   get isLoanSantionedStatusNo(){
        return this.bookingDetails?.isLoanSanctioned === 'No';
   }

   get isModeOfFundingLoanRelated(){
        return this.bookingDetails?.modeOfFunding === 'Loan' || this.bookingDetails?.modeOfFunding === 'Partial Funding';
   }


   initializeBookingDetails(){
        this.bookingDetails = {
            ...this.bookingDetails,
            'opportunityName' : this.quote.Opportunity__r.Name,
            'projectName' : this.quote.Project__r.Name,
            'towerName' : this.quote.Tower__r.Name,
            'unitName' : this.quote.Unit__r.Name,
            'floorNo' : this.quote.Unit__r.Floor__c,
            'totalCarpetArea' : this.quote.Unit__r.Total_carpet_Sq_Ft__c,
            'remarks' : '',
            'otherChannelPartners' : '',
            'isLoanSanctioned' : '',
            'modeOfFunding' : ''
        }
   }

   handleBookingDetailsChange(event){
        const fieldName = event.target.dataset.fieldName;
        const fieldValue = event.target.value ? event.target.value : event.target.checked;

        if(fieldName == 'isLoanSanctioned' && fieldValue == null){
            this.bookingDetails = {
                ...this.bookingDetails,
                [fieldName] : ''
            }
        }

        if(fieldValue != null){
            this.bookingDetails = {
                ...this.bookingDetails,
                [fieldName] : fieldValue
            }
        }
        console.log('this.bookingDetails : ' + JSON.stringify(this.bookingDetails));
   }
   


    /*
     * --- Get Applicant Details --- 
        
     applicantDetails : {
            data : {
                'Primary Applicant' : {
                    applicant : {},
                    applicantDocuments : {},
                }
                
                'Secondary Applicant' : {
                    applicant : {},
                    applicantDocuments : {},
                }
                ...
            }
            metadata : {
                currentApplicantDetails : #ref,
                currentApplicantSelected : 'Key'
                applicantNos : ['Primary Applicant','Secondary Applicant','Third Applicant']
            }
      }
    */
    @wire(getObjectInfo, { objectApiName : APPLICANT_OBJECT })
    applicantObjectInfo;

    @wire(getPicklistValues, {
            recordTypeId : "$applicantObjectInfo.data.defaultRecordTypeId",
            fieldApiName : APPLICANT_NUMBER_FIELD,
    })
    handleApplicantNoPicklistValues({data, error}){
        if(data){
            console.log('data : ' +JSON.stringify(data));
            this.applicantNumber_OPTIONS = data.values.map(picklistValue => {
                return  {
                    'label' : picklistValue.label,
                    'value' : picklistValue.value
                }
            });
            this.initializeApplicantDetails();
        }
        if(error){
            console.log('Error occurred while retriving picklist values for Applicant Number');
        }
    }

    // Get Applicant Wrapper
    initializeApplicantDetails(){
        this.applicantDetails = {
            data : {
                [this.applicantNumber_OPTIONS[0].value] : {
                    applicant : {},
                    applicantDocuments : {}
                }
            },
            metadata : {
                currentApplicantDetails : null,
                currentApplicantSelected : null,
                applicantNumbers : this.applicantNumber_OPTIONS
            }
        }
        console.log('this.applicantDetails : ' + JSON.stringify(this.applicantDetails));
        
    }
    @wire(getApplicantWrapper, {})
    handleApplicantWrapper({error, data}){
        if(data){
            this.applicantWrapper = data;
            console.log('this.applicantWrapper :  ' + JSON.stringify(this.applicantWrapper));
            
        }
        if(error){
            console.log('Error occurred while getting Applicant Wrapper');
        }
    }

   


    getApplicantDoc() {
        var fieldValue ;

        var _nationality = this.getApplicantData.Nationality__c || 'Indian';
        console.log('fieldValue ' + fieldValue );
        console.log('_nationality' + _nationality);
        console.log('this.oppId' + this.oppId);
        console.log('_nationality' + this.getApplicantData.Nationality__c);
        
        ApplicantdocumentDetails({ fieldValue: fieldValue, nationality : _nationality, oppId: this.oppId, tabKey: 'Applicant 1' })
            .then(result => {
                this.getApplicantData = result.map((item, index) => ({
                    key: `Applicant ${index + 1}`,
                    ap: item.ap,
                    documents: item.documents,
                }));
                console.log('getApplicantData ', JSON.stringify(this.getApplicantData));
            });
    }

    @wire(getBookingDocumentNames)
    handleBookingDocumentNames({error, data}){
        if(data){
            
            data.map(bookingDocumentName => {
                var bookingDocument = {
                    'fileName' : bookingDocumentName,
                    'documentName' : bookingDocumentName,
                    'actualFileName' : '',
                    'base64' : '',
                    'isUploaded' : false
                }

                this.otherBookingDocumentNames[bookingDocumentName] = bookingDocument;
            })
            console.log('this.otherBookingDocumentNames : ' + JSON.stringify(this.otherBookingDocumentNames));
        }
        if(error){
            console.log('Error in getting the other booking documents');
        }
    }

    get getBookingDocumentNamesData(){
        var response = {
            isEmpty : this.otherBookingDocumentNames == null || this.otherBookingDocumentNames == undefined,
            data : Object.values(this.otherBookingDocumentNames)?.map(doc => {
                return {
                    'bookingDocumentName' : doc.fileName, 'uploadedFileName' : doc.actualFileName
                }
            })
        }
        return response;
    }

    // Handle File Upload
    handleOtherDocumentFileUpload(event){
        var fileType = event.target.dataset.documentType;
        var files = event.target.files;

        const file = files[0];
        const fileExtension = this.getFileExtension(file.name);

        var reader = new FileReader();
        reader.onload = () => {
            var base64 = reader.result.split(",")[1];
            this.otherBookingDocumentNames[fileType].base64 = base64;
            this.otherBookingDocumentNames[fileType].fileName = fileType + '.' + fileExtension;
            this.otherBookingDocumentNames[fileType].actualFileName = file.name;

            console.log('this.otherBookingDocumentNames : ' + JSON.stringify(this.otherBookingDocumentNames));
        };
        reader.readAsDataURL(file);
    }

    getFileExtension(filename) {
        const lastDotIndex = filename.lastIndexOf(".");
        if (lastDotIndex === -1) {
          return "";
        }
        return filename.substring(lastDotIndex + 1);
    }
      

    // Upload Other Booking Documents
    uploadOtherBookingDocuments(bookingID){
        const files = Object.values(this.otherBookingDocumentNames);

        console.log('files  : ' + JSON.stringify(files));
        var isNoFilesUploaded = true;
        files.map(file => {
            isNoFilesUploaded = isNoFilesUploaded && (file.base64 == '' || file.base64 == null)
        })
        if(isNoFilesUploaded){
            this.showCustomToast('success', 'Booking Created Successfully');
            this.isSpinner = false;
            location.replace('/' + bookingID);
            return;
        }

        files.map(bookingDocument => {
            if(bookingDocument.base64 != null && bookingDocument.base64 != '' ){
                console.log('bookingDocument : '  + JSON.stringify(bookingDocument));
                
                createBookingDocuments({ bookingDocuments : bookingDocument, bookingID : bookingID})
                .then(result => {
                    console.log('result : ' + JSON.stringify(result));
                    
                    var _documentName = bookingDocument.documentName;
                    this.otherBookingDocumentNames[_documentName].isUploaded = true;

                    var finalUploadStatus = Object.values(this.otherBookingDocumentNames).reduce((allUploaded, currentDocument) => {
                        return currentDocument.base64 == '' || (allUploaded && currentDocument.isUploaded);
                    }, true);
                    if(finalUploadStatus){
                        this.isSpinner = false;
                        this.showCustomToast('success', 'Booking Created Successfully');
                        location.replace('/' + bookingID);
                    }
                    console.log('finalUploadStatus : ' + finalUploadStatus);
                })
                .catch(error => {
                    console.log('error : ' + JSON.stringify(error));
                })

            }
        })
        
    }



    get getToastClass() {
        return `slds-notify slds-notify_toast slds-theme_${this.toastVariant}`;
    }

    get iconName() {
        switch (this.toastVariant) {
            case 'success':
                return 'utility:success';
            case 'error':
                return 'utility:error';
            case 'warning':
                return 'utility:warning';
            case 'info':
                return 'utility:info';
            default:
                return 'utility:info'; // Default icon
        }
    }

    get toastTextColor() {
        switch (this.toastVariant) {
            case 'success':
                return 'success'; // Or another suitable color for success
            case 'error':
                return 'error';
            case 'warning':
                return 'warning';
            case 'info':
                return 'info';
            default:
                return 'black'; // Default color
        }
    }

    showCustomToast(type, message, timeout = 5000) { // Timeout in milliseconds
        this.toastVariant = type;
        this.toastMessage = message;
        this.showToast = true;
        setTimeout(() => {
            this.showToast = false;
        }, timeout);
    }

    closeToast() {
        this.showToast = false;
    }

    getQuotationDetailsCall() {
        this.showSpinner = true;
        getQuotationDetails({ qId: this.qId })
            .then(result => {
                console.log('result: ' + JSON.stringify(result));
                this.quote = result;
                this.uId = this.quote.Unit__c;
                this.oppId = this.quote.Opportunity__c;
                this.initializeBookingDetails();
                this.getApplicantDoc();
                this.showSpinner = false;
            })
            .catch(error => {
                this.error = error;
                this.quote = undefined;
                this.showSpinner = false;
            })
    }

    handleBookingWrapper() {
        getBookingWrapper({ oppId: this.oppId })
            .then((result) => {
                this.bkWrapper = result;
                console.log('data: ' + JSON.stringify(this.bkWrapper));
            })
            .catch((error) => {
                this.error = error;
                this.bkWrapper = undefined;
            });
    }

    getReceiptWrapperMethod() {
        getReceipts({})
            .then((result) => {
                console.log('result : ' + JSON.stringify(result));
                
                if (result && result.length > 0) {
                    this.getReceiptData = result.map((item, index) => ({
                        key: `Receipt ${index + 1}`,  // Unique key for each receipt
                        rc: item                      // The receipt data from the result
                    }));
                }
            })
            .catch((error) => {
                console.error('Error fetching receipt data: ', error);
            });
    }

    //    @wire(getReceipts)
    //     wiredReceipts({ error, data }) {

    //     }
    addReceipt() {
        console.log('Active tab value:', this.activeTabValue);
        const newReceipt = {
            key: `Receipt ${this.getReceiptData.length + 1}`,
            rc: {}
        };
        this.getReceiptData.push(newReceipt);
        this.getReceiptData = [...this.getReceiptData];
    }
    removeTabReceipt(event) {

        const tabIndexToRemove = parseInt(event.target.dataset.index, 10);
        console.log('TAB INDEX:', tabIndexToRemove);
        const key = event.currentTarget.dataset.tabvalue;

        if (key === 'Receipt 1') {
            alert('Receipt 1 Cannot be Removed.');
            return;
        } else {
            for (var i = 0; i < this.getReceiptData.length; i++) {
                if (this.getReceiptData[i].key == key) {
                    //alert('FOund')
                    this.getReceiptData.splice(tabIndexToRemove, 1);
                    this.getReceiptData.forEach((receipt, index) => {
                        receipt.key = `Receipt ${index + 1}`;
                        receipt.rc = {}
                    });
                    this.getReceiptData = [...this.getReceiptData];
                    console.log(JSON.stringify(this.getReceiptData));
                }
            }

        }

    }

    handleReceiptInfo(event) {
        const tabKey = event.currentTarget.dataset.key;
        const fieldApiName = event.target.fieldName;
        const fieldValue = event.target.value;
        this.getReceiptData = this.getReceiptData.map(item => {
            if (item.key === tabKey) {
                return { ...item, rc: { ...item.rc, [fieldApiName]: fieldValue } };
            }
            return item;
        });
        console.log('getReceiptData: ' + JSON.stringify(this.getReceiptData));
    }

    handleBookingInfo(event) {
        const fieldName = event.target.fieldName;
        const value = event.target.value;
        this.getBookingWrapperList = {
            ...this.bkWrapper.bk,
            [fieldName]: value
        };

        this.bkWrapper = { bk: this.getBookingWrapperList };
        console.log('bkWrapper: ' + JSON.stringify(this.bkWrapper));
        if (fieldName == 'Mode_of_Funding__c') {
            if (this.bkWrapper.bk.Mode_of_Funding__c == 'Loan' || this.bkWrapper.bk.Mode_of_Funding__c == 'Partial Funding') {
                this.showBankDetails = true;
                this.showLoanType = true;
            } else {
                this.showBankDetails = false;
                this.showLoanType = false;
            }
        }
    }

    addApplicant() {
        console.log('Active tab value:', this.activeTabValue);
        const newApplicant = {
            key: `Applicant ${this.getApplicantData.length + 1}`,
            ap: {},
            documents: [],
        };
        this.getApplicantData.push(newApplicant);
        this.getApplicantData = [...this.getApplicantData];
    }
    removeTab(event) {
        const tabIndexToRemove = parseInt(event.target.dataset.index, 10);
        console.log('TAB INDEX:', tabIndexToRemove);
        const key = event.currentTarget.dataset.tabvalue;

        if (key === 'Applicant 1') {
            alert('Applicant 1 Cannot be Removed.');
        } else {
            const indexToRemove = this.getApplicantData.findIndex(applicant => applicant.key === key);
            if (indexToRemove !== -1) {
                this.getApplicantData.splice(indexToRemove, 1);
                this.getApplicantData.forEach((applicant, index) => {
                    console.log(`Applicant ${index + 1}`);
                    applicant.key = `Applicant ${index + 1}`;
                });
                this.getApplicantData = [...this.getApplicantData];
                console.log(JSON.stringify(this.getApplicantData));
            } else {
                console.log('Applicant not found:', key);
            }
        }
    }

    callDocument(tabKey, fieldValue) {
        
        console.log('this.getApplicantData---- :  '+ JSON.stringify(this.getApplicantData));
        console.log('this.tabKey---- :  '+ JSON.stringify(tabKey));
        
        var nationality = '';
        this.getApplicantData.map(applicant => {
            if(applicant.key == tabKey ){
                nationality = applicant.ap.Nationality__c;
            }
        });

        ApplicantdocumentDetails({ fieldValue: fieldValue, nationality : nationality , oppId: this.oppId, tabKey: tabKey })
            .then(result => {
                console.log('result', JSON.stringify(result));

                this.getApplicantData = this.getApplicantData.map((item, index) => {
                    console.log('item', JSON.stringify(item));
                    if (item.key === tabKey) {
                        if (result[index] && result[index].ap) {
                            item.ap = { ...item.ap, ...result[index].ap };
                        }

                    }
                    return item;
                });
                this.documentsArray = [];

                result.forEach((docItem, docIndex) => {
                    console.log('docItem', JSON.stringify(docItem.documents));

                    if (docItem.documents != undefined && docItem.documents) {
                        let mergedObject = {
                            ...docItem.documents,
                            key: tabKey,
                            filename: null,
                            base64: null,
                            fileData: null,
                            fileUploader: null,
                            type: docItem.documents.Name,
                            index: docIndex
                        };
                        this.documentsArray.push(mergedObject);
                    }
                });

                const applicantIndex = this.getApplicantData.findIndex(item => item.key === tabKey);
                if (applicantIndex !== -1) {
                    this.getApplicantData[applicantIndex].documents = this.documentsArray;
                }

                console.log('getApplicantDataBeforeDocument: ', JSON.stringify(this.getApplicantData));
            })
            .catch(error => {
                console.error(error.message);
            });

            
    }

    handleApplicant(event) {
        try {
            const tabKey = event.currentTarget.dataset.key;
            const fieldApiName = event.target.fieldName;
            const fieldValue = event.target.value;

            console.log('tabKey:', tabKey);
            console.log('fieldValue:', fieldValue);
            console.log('fieldApiName:', fieldApiName);

            //  console.log('fieldApiName::'+fieldApiName +' fieldValue:: '+ fieldValue);
            const applicantIndex = this.getApplicantData.findIndex(item => item.key === tabKey);
            if (applicantIndex !== -1) {
                const updatedApplicant = { ...this.getApplicantData[applicantIndex] };
                updatedApplicant.ap = { ...updatedApplicant.ap, [fieldApiName]: fieldValue };
                console.log('updatedApplicant::' + JSON.stringify(updatedApplicant));
                if (updatedApplicant.ap.Mailing_Address_Same_as_PermanentAddress__c === true) {

                    updatedApplicant.ap.Mailing_Address__c = updatedApplicant.ap.Permanent_Address__c;
                    updatedApplicant.ap.Mailing_Country__c = updatedApplicant.ap.Permanent_Country__c;
                    updatedApplicant.ap.Mailing_State__c = updatedApplicant.ap.Permanent_State__c;
                    updatedApplicant.ap.Mailing_City__c = updatedApplicant.ap.Permanent_City__c;
                    updatedApplicant.ap.Mailing_Pincode__c = updatedApplicant.ap.Permanent_Pin_Code__c;
                }
                this.getApplicantData.splice(applicantIndex, 1, updatedApplicant);
    
                if(fieldApiName === 'Mailing_Address_Same_as_PermanentAddress__c' && fieldValue == false){
                    updatedApplicant.ap.Mailing_Address__c = '';
                    updatedApplicant.ap.Mailing_Country__c = '';
                    updatedApplicant.ap.Mailing_State__c = '';
                    updatedApplicant.ap.Mailing_City__c = '';
                    updatedApplicant.ap.Mailing_Pincode__c = '';
                }    
    
            }
            console.log('Applicant Data::' + JSON.stringify(this.getApplicantData));

            if (fieldValue && fieldApiName === 'Nationality__c') {
                var isDocUploadedRequired = 'No';
                this.getApplicantData.forEach(applicant => {
                    if(applicant.key === tabKey && applicant.ap != undefined && applicant.ap != null){
                        isDocUploadedRequired = applicant.ap.Document_Upload_Required__c || 'No';
                    }
                })

                this.callDocument(tabKey, isDocUploadedRequired);
            }
            if (fieldValue && fieldApiName === 'Document_Upload_Required__c') {
                this.callDocument(tabKey, fieldValue);
                if (fieldValue === 'No') {
                    this.isdocumentRequired = false;
                } else if (fieldValue === 'Yes') {
                    this.isdocumentRequired = true;
                } else {
                    this.isdocumentRequired = false;
                }
            } else if (fieldApiName === 'PAN_Number__c') {
                //alert('textt');
                const panNumber = event.detail.value;
                console.log('Inside Pan:::' + panNumber);
                const isValidPan = this.sValidPanCardNo(panNumber);
                console.log('isValidPan: ' + isValidPan);

                if (isValidPan === 'false') {
                    this.showErrorPan = true;
                    this.showMsg = 'Please Enter Valid PAN Number ';
                } else {
                    this.showErrorPan = false;
                }
            } else if (fieldApiName === 'Aadhar_Number__c') {
                const aadharNumber = event.detail.value;
                const isValidAadhar = this.validateAadharNumber(aadharNumber);

                if (!isValidAadhar) {
                    this.showError = true;
                    this.showMsg = 'Please Enter Valid Aadhar Number ';
                } else {
                    this.showError = false;
                }
            } else if (fieldApiName === 'PIN__c') {
                const pinNumber = event.detail.value;
                const isValidPIN = this.validPINNumber(pinNumber);

                if (!isValidPIN) {
                    this.showErrorPIN = true;
                    this.showPINMsg = 'Please Enter Valid PIN Code';
                } else {
                    this.showErrorPIN = false;
                }
            } else if (fieldApiName === 'Mailing_Pincode__c') {
                const MailingPinNumber = event.detail.value;
                const isValidMailingPIN = this.validMailingPINNumber(MailingPinNumber);

                if (!isValidMailingPIN) {
                    this.showErrorMailingPIN = true;
                    this.showMailingPINMsg = 'Please Enter Valid Mailing PIN Code';
                } else {
                    this.showErrorMailingPIN = false;
                }
            }

        } catch (error) {
            console.error(error.message)
        }
    }

    sValidPanCardNo(panNumber) {
        let regex = new RegExp(/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/);
        if (panNumber == null) {
            return 'false';
        }
        if (regex.test(panNumber) == true) {
            return 'true';
        }
        else {
            return 'false';
        }
    }

    validateAadharNumber(aadharNumber) {
        const aadharRegex = /^\d{12}$/;
        return aadharRegex.test(aadharNumber);
    }

    validPINNumber(pinNumber) {
        const validCodeRgx = /^\d{6}$/;
        return validCodeRgx.test(pinNumber);

    }

    validMailingPINNumber(MailingPinNumber) {
        const validCodeRgx = /^\d{6}$/;
        return validCodeRgx.test(MailingPinNumber);

    }
    changeBookingdate(event) {
        try {
            this.bookingDate = event.target.value;
            console.log(this.bookingDate);
        } catch (error) {

            console.error(error.message);
        }
    }

    isPrimaryApplicantDataValid() {
        const allApplicants = this.getApplicantData;
        let allValid = true;
        for (const applicant of allApplicants) {
            const { ap } = applicant;
            const isValid = !!ap.Applicant_Title__c && !!ap.Name && !!ap.Applicant_Number__c;
            if (!isValid) {
                allValid = false;
                break;
            }
        }
        return allValid;
    }

    isReceiptContributionType() {
        const allReceipts = this.getReceiptData;
        let allValid = true;

        for (const receipt of allReceipts) {
            const { rc } = receipt;
            console.log('Receipt rc:', JSON.stringify(rc));

            if (rc.Receipt_Type__c === 'Flat Cost') {
                const isValid = !!rc.Contribution_Type__c && rc.Contribution_Type__c.trim() !== '';
                if (!isValid) {
                    console.error(`Invalid Receipt: ${JSON.stringify(receipt)}`);
                    allValid = false;
                    break;
                }
            }
        }

        return allValid;
    }


    ismobilenumberValid() {
        const allApplicants = this.getApplicantData;
        let allValid = true;
        for (const applicant of allApplicants) {
            const { ap } = applicant;
            const isValid = !!ap.Primary_Mobile__c;
            if (!isValid) {
                allValid = false;
                break;
            }
        }
        return allValid;
    }
    isDOBValid() {
        const allApplicants = this.getApplicantData;
        let allValid = true;
        for (const applicant of allApplicants) {
            const { ap } = applicant;
            const isValid = !!ap.DOB__c;
            if (!isValid) {
                allValid = false;
                break;
            }
        }
        return allValid;
    }


    isTypeOfApplicantValid() {
        const allApplicants = this.getApplicantData;
        let allValid = true;
        for (const applicant of allApplicants) {
            const { ap } = applicant;
            const isValid = !!ap.Type_Of_Applicant__c;
            if (!isValid) {
                allValid = false;
                break;
            }
        }
        return allValid;
    }
    isResidentialValid() {
        const allApplicants = this.getApplicantData;
        let allValid = true;
        for (const applicant of allApplicants) {
            const { ap } = applicant;
            const isValid = !!ap.Residential_Status__c;
            if (!isValid) {
                allValid = false;
                break;
            }
        }
        return allValid;
    }
    isaadharValid() {
        const allApplicants = this.getApplicantData;
        let allValid = true;
        for (const applicant of allApplicants) {
            const { ap } = applicant;
            const isValid = !!ap.Aadhar_Number__c;
            if (!isValid) {
                allValid = false;
                break;
            }
        }
        return allValid;
    }

    isPanValid() {
        const allApplicants = this.getApplicantData;
        let allValid = true;
        for (const applicant of allApplicants) {
            const { ap } = applicant;
            const isValid = !!ap.PAN_Number__c;
            if (!isValid) {
                allValid = false;
                break;
            }
        }
        return allValid;
    }

    isdocumentUploadRequired() {
        const allApplicants = this.getApplicantData;
        let allValid = true;
        for (const applicant of allApplicants) {
            const { ap } = applicant;
            const isValid = !!ap.Document_Upload_Required__c;
            if (!isValid) {
                allValid = false;
                break;
            }
        }
        return allValid;
    }

    get getApplicantDetails(){
        console.log('this.getApplicantData : ' + JSON.stringify(this.getApplicantData));
    }

    openfileUpload(event) {
        try {
            // Check if any file is selected
            if (!event.target.files || event.target.files.length === 0) {
                console.error('No files selected.');
                return; // Exit if no files are selected
            }

            var file = event.target.files[0];
            var getSize = file.size;

            if (getSize > 3145728) {
                alert('File size exceeds 3 MB. Please choose a smaller file.');
                return;
            }


            let index = event.target.dataset.id ? parseInt(event.target.dataset.id) : null;
            let applicantkey = event.target.dataset.applicantkey;

            if (index === null || !applicantkey) {
                console.error('Missing data attributes.');
                return;
            }

            console.log('applicantkey', applicantkey);
            let fieldName = event.target.name;
            let value = event.target.value;
            console.log('Selected value:', value);


            // --- Store Uploaded Files ---
            var selectedApplicantData = null;
            var selectedApplicantIndex = -1;
            for (let i = 0; i < this.getApplicantData.length; i++) {
                const applicantData = this.getApplicantData[i];
                if(applicantData['key'] === applicantkey){
                    selectedApplicantData = {...applicantData};
                    selectedApplicantIndex = i;
                    break;
                }
            }


            if(selectedApplicantData != null && selectedApplicantIndex != -1){
                var matchingDocument = selectedApplicantData?.documents?.find(doc => doc.index === index);
                var matchingDocIndex = selectedApplicantData?.documents?.find((doc, docIdx) => {
                    if(doc.index === index)  return docIdx;
                });

                var reader = new FileReader();
                reader.onload = () => {
                    var base64 = reader.result.split(",")[1];
                    matchingDocument.base64 = base64;
                    matchingDocument.filename = file.name;        

                    console.log('matchingDocument ::: ' + JSON.stringify(matchingDocument));                    
                    
                    selectedApplicantData.documents[matchingDocIndex] = matchingDocument;
                    this.getApplicantData[selectedApplicantIndex] = selectedApplicantData;

                    console.log('this.getApplicantData : ' + JSON.stringify(this.getApplicantData));
                    
                };
                reader.readAsDataURL(file);
            }

            // -----------

        } catch (error) {
            console.error('An error occurred:', error);
        }
        console.log('Updated Documents:', JSON.stringify(this.getApplicantData));

    }




    handleSave() {

        console.log('this.rcWrapper : ' + JSON.stringify(this.rcWrapper));
        
        // alert('bkWrapper: '+JSON.stringify(this.bkWrapper));
        // alert('applicantData: '+ JSON.stringify(this.getApplicantData))
        // alert('Quotation: '+ JSON.stringify(this.quote))
        // alert('LegalEntity: '+ JSON.stringify (this.testData));
        if (!this.isPrimaryApplicantDataValid()) {
            this.showCustomToast('error', 'Please Enter Salutation, Name, and Applicant Number');
            return;
        } 
        else if (this.bookingDetails.modeOfFunding == null || this.bookingDetails.modeOfFunding == '') {
            this.showCustomToast('error', 'Please enter mode of funding details');
            return;
        }
        // else if ((this.bkWrapper.bk.Mode_of_Funding__c == 'Loan' || this.bkWrapper.bk.Mode_of_Funding__c == 'Partial Funding') && this.bkWrapper.bk.Loan_Type__c == null || this.bkWrapper.bk.Loan_Type__c == '') {
        //     this.showCustomToast('error', 'Please enter loan type details');
        //     return;
        // }
         else if (!this.ismobilenumberValid()) {
            this.showCustomToast('error', 'Please Enter Mobile Number');
            return;
        } else if (!this.isDOBValid()) {
            this.showCustomToast('error', 'Please Enter Date of Birth');
            return;
        } 
        else if (!this.isTypeOfApplicantValid()) {
            this.showCustomToast('error', 'Please Enter Type of Applicant');
            return;
        } else if (!this.isaadharValid()) {
            this.showCustomToast('error', 'Please Enter Aadhar Number');
            return;
        } else if (!this.isPanValid()) {
            this.showCustomToast('error', 'Please Enter Pan Number');
            return;
        }  else if (!this.isdocumentUploadRequired()) {
            this.showCustomToast('error', 'Please Select Document Upload Required');
            return;
        } else if (this.bookingDetails.bookingDate == null) {
            this.showCustomToast('error', 'Please Enter Booking Date');
            return;
        } else if (this.bookingDetails.remarks == null && this.bookingDetails.remarks == ''){
            this.showCustomToast('error', 'Please Enter Booking Remarks');
            return;
        }
        else if (this.bookingDetails.modeOfFunding == null && this.bookingDetails.modeOfFunding == ''){
            this.showCustomToast('error', 'Please Enter Mode Of Funding');
            return;
        }
        // } else if (!this.isReceiptContributionType()) {
        //         this.showCustomToast('error', 'Please Select Contribution Type');
        //         return;
        // } else if (this.rcWrapper && this.rcWrapper.rc.Payment_Type__c == null) {
        //     this.showCustomToast('error', 'Please Select Payment Type');
        //     return;
        // } else if (this.rcWrapper && this.rcWrapper.rc.Payment_Status__c == null) {
        //     this.showCustomToast('error', 'Please Select Payment Status');
        //     return;
        // } else if (this.rcWrapper && this.rcWrapper.rc.Receipt_Type__c == null) {
        //     this.showCustomToast('error', 'Please Select Receipt Type');
        //     return;
        // } else if (this.rcWrapper && this.rcWrapper.rc.Transaction_ID__c == null) {
        //     this.showCustomToast('error', 'Please Enter Transaction ID');
        //     return;
        // } else if (this.rcWrapper && this.rcWrapper.rc.Receipt_Date__c == null) {
        //     this.showCustomToast('error', 'Please Enter Receipt Date');
        //     return;
        // } else if (this.rcWrapper && this.rcWrapper.rc.Amount__c == null) {
        //     this.showCustomToast('error', 'Please Enter Receipt Amount');
        //     return;
        else {

                console.log('applicantData : ' + JSON.stringify(this.applicantData));
                console.log('this.bookingDetails : ' + JSON.stringify(this.bookingDetails));

                
                this.isSpinner = true;
                createBookingRecord({
                    bkWrapper: this.bkWrapper,
                    applicantData: JSON.stringify(this.getApplicantData),
                    quotationDetails: this.quote,
                    receiptData: JSON.stringify(this.getReceiptData),
                    bookingDetails : this.bookingDetails
                })
                    .then(result => {
                        console.log('Booking: ', result);
                        // this.isSpinner = false;

                        var result1 = this.uploadOtherBookingDocuments(result);
                        console.log('result1 : ' + result1);
                    })
                    .catch((error) => {
                        this.showSpinner = false;
                        this.showCustomToast('error', 'Error Occured Please Contact System Administrator');
                        console.log('error is::' + JSON.stringify(error));
                    })
            }
    }
}