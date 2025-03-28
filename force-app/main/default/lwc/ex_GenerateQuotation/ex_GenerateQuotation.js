import { LightningElement, api, track, wire } from 'lwc';
import getOppDetails from '@salesforce/apex/Ex_InventoryMatrix.getOppDetails';
import getQuotationWrapper from '@salesforce/apex/Ex_GenerateQuotation.getQuotationWrapper';
import getUnitDetails from '@salesforce/apex/Ex_GenerateQuotation.getUnitDetails';
import getCarParkDetails from '@salesforce/apex/Ex_GenerateQuotation.getCarParkDetails';
import getPaymentSchemeDetails from '@salesforce/apex/Ex_GenerateQuotation.getPaymentSchemeDetails';
import getPaymentScheduleDetails from '@salesforce/apex/Ex_GenerateQuotation.getPaymentScheduleDetails';
import getPicklistValuesFromApex from '@salesforce/apex/Ex_GenerateQuotation.getPicklistValues';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import validateUpdatedPaymentScheduleDetails from '@salesforce/apex/Ex_GenerateQuotation.validateUpdatedPaymentScheduleDetails';
import getUpdatedPaymentScheduleDetails from '@salesforce/apex/Ex_GenerateQuotation.getUpdatedPaymentScheduleDetails';
import getModifiedPaymentScheduleDetails from '@salesforce/apex/Ex_GenerateQuotation.getModifiedPaymentScheduleDetails';
import saveQuotationDetails from '@salesforce/apex/Ex_GenerateQuotation.saveQuotationDetails';
import currencyFormat from '@salesforce/apex/Ex_InventoryPriceManagementServices.currencyFormat';
import getChargeDetails from '@salesforce/apex/Ex_GenerateQuotation.getChargeDetails';
import Other_Charges__c from '@salesforce/schema/Other_Charges__c';
import Charge_Type__c from '@salesforce/schema/Other_Charges__c.Charge_Type__c';
import getOtherCharges from "@salesforce/apex/Ex_GenerateQuotation.getOtherCharges";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getAccountInfo from "@salesforce/apex/Ex_GenerateQuotation.getAccountInfo";




export default class Ex_GenerateQuotation extends LightningElement {
    @api uId;
    @api oppId;
    @api qtype;
    @track fetchOpp;
    @track unit;
    @track storeProjectId = '';
    @track QuotationWrapper = { q: {} };
    @track getQuotationWrapperList = [];

    @track carParkList = [];
    @track updatedCarParkList = [];
    @track editPaymentScheduleMode = false;
    @track totalCarParkAmount = 0;
    @track totalCarParkCount = 0;

    @track showToast = false;
    @track toastMessage = '';
    @track toastTitle = null;
    @track toastVariant = ''; // success, warning, error
    @track isQuotationModified = false;

    @track paymentMilestoneWrapperList = [];
    @track updatedPaymentMilestoneWrapperList = [];
    @track totalCarParkAmountString = '0.00/-';

    @track allPriceOriginalInfoMap = [];
    @track allPriceInfoMap = [];
    @track allPriceOriginalInfoFormattedMap = [];
    @track allPriceInfoFormattedMap = [];
    @track allPriceDetailMap = []; //For Display Use

    @track milestoneType = [];
    @track amountType = [];

    @track actionType = '';
    @track rowIndex = null;
    @track agSeqNumber = 0;

    @track isPaymentScheduleEnable = false;
    @track editPaymentScheduleMode = false;
    @track isPaymentScheduleUpdated = false;

    @track paymentSchemeList = [];
    @track showPaymentScheduleData = false;
    @track selectedPaymentSchemeName = '';
    @track selectedPaymentScheme = '';

    @track showTable = false;
    @track priceListMap = [];
    @track priceListGroupMap = [];

    @track getOrginalAVValue = 0;
    @track originalSDR = 0;
    @track referalDiscount = false;
    @track getTotalOrginalAmount = 0;
    @track getTotalModifiedAmount = 0;
    @track getOriginalGstAmount = 0;
    @track getModifiedAVValue = 0;
    @track getModifiedSDR = 0;
    @track getModifiedGstAmount = 0;


    @track formatgetOrginalAVValue = '';
    @track formatgetTotalModifiedAmount = '';
    @track formatgetTotalOrginalAmount = '';
    @track formatgetModifiedGstAmount = '';
    @track formatgetOriginalGstAmount = '';
    @track formatgetModifiedSDR = '';
    @track formatoriginalSDR = '';
    @track formatgetModifiedAVValue = '';
    @track showPaymentPlanforTenant = false;

    // @track getTotalOtherCharges = 0;
    @track getModifiedTotalOtherCharges = 0;
    @track formatTotalOtherCharges = '';
    @track formatModifiedTotalOtherCharges = '';

    @track isValidationError = false;;
    @track showCalculate = false;
    @track showConfirm = false;

    // -----------------------------

    // --- Discount ---
    @track appliedDiscount = 0;
    @track isQuotationOpenfromAccount = false;

    // --- Toast Error --- 
    @track showErrorMessage = false;
    @track errorMessage = {
        'title': '',
        'content': ''
    };

    @track originalFinalCommittedArea = 0;
    @track getDiffArea = 0;
    @track diffDate = null;
    @track getBillAmount = 0;
    @track dynamiclabel = ''


    // --- Pricing Scheme and Payment Plan
    @track pricingPlanOptions = [
        { label: 'Standard Plan', value: 'standard' },
        { label: 'Box Plan', value: 'box' },
    ];
    @track BOX_PLAN = 'box';
    @track STANDARD_PLAN = 'standard';

    @track selectedPricingPlan = '';
    @track otherCharges = {
        'data': {
            'originalCharges': {
                'otherChargeType': {
                    'id': 'recordTypeID',
                    'sequenceNo': 0,
                    'chargeName': 'otherChargeType',
                    'chargeAmount': 40000,
                    'GSTPercentage': 18.00,
                    'chargeAmountIncludingGST': 47200,
                    'availableOtherChargeTypes': []
                }
            },
            'modifiedCharges': {
                'otherChargeType': {},
                'otherChargeType': {},
                'otherChargeType': {}
            },
            'newCharges': {
                'otherChargeType': {},
                'otherChargeType': {},
                'otherChargeType': {}
            },

        },
        'metadata': {
            'availableOtherChargeTypes': []
        }
    }
    @track chargeDetails = {
        'quotationType': {
            'originalCharges': {
                'agreementValue': 7000000,
                'otherCharges': 100000,
                'registrationCharges': 50000,
            },
            'modifiedCharges': {
                'agreementValue': 8000000,
                'otherCharges': 200000,
                'registrationCharges': 70000,
            },
            'newCharges': {
                'agreementValue': 7000000,
                'otherCharges': 100000,
                'registrationCharges': 50000,
            }
        }
    };

    

    handlediffDate(event) {
        this.diffDate = event.target.value || event.detail.value;
        console.log('diffDate: ' + this.diffDate);
    }

    handleFinalCommittedAreaChange(event){

        var finalCommitedArea = event.target.value;

        
        if(isNaN(finalCommitedArea) || finalCommitedArea == null || finalCommitedArea == undefined || finalCommitedArea <= 0){
            event.currentTarget.value = 0;
            this.fetchOpp.Final_Committed_Area__c = 0;
        }
        else{
            this.fetchOpp.Final_Committed_Area__c = parseFloat(finalCommitedArea);
            console.log('this.fetchOpp.Final_Committed_Area__c : ' + this.fetchOpp.Final_Committed_Area__c);
        }
        this.showCalculate = true;
    }

    get diffAreaNegative() {
        return this.getDiffArea < 0;   
    }


    get getToastClass() {
        return `slds-notify slds-notify_toast slds-theme_${this.toastVariant}`;
    }

    get innerClass() {
        return 'slds-icon_container slds-icon-utility-close slds-m-right_small slds-no-flex slds-align-top';
    }
    connectedCallback() {
        console.log('qtype: ' + this.qtype);
        if (this.qtype === '') {
            this.handleOppData();
        }
        else if (this.qtype === 'Tenant') {
            this.handleTenantData();
            this.isQuotationOpenfromAccount = true;
            console.log('qtype: ' + this.qtype);
            console.log('uId: ' + this.uId);
            this.pricingPlanOptions = this.pricingPlanOptions.filter(element => element.value !== 'box');
        }
        console.log('pricingPlanOptions: ' + JSON.stringify(this.pricingPlanOptions));



    }


    handleTenantData() {
        if (this.oppId !== undefined) {
            getAccountInfo({ accId: this.oppId })
                .then((result) => {
                    console.log("result ", result);
                    this.fetchOpp = result;
                    this.originalFinalCommittedArea = this.fetchOpp.Final_Committed_Area__c;
                    this.error = undefined;
                    if (this.fetchOpp.Society__r.Project__r.Id != undefined) {
                        this.isOppProject = true;
                        this.storeProjectId = this.fetchOpp.Society__r.Project__r.Id;
                        this.handleUnitData();
                        //this.getDiffAreaCal();

                        this.showSpinner = false;
                    }
                })
                .catch((error) => {
                    this.error = error;
                    this.fetchOpp = undefined;
                });
        }

    }



    calculateChargeDetailsTenantWise(chargeState = 'modifiedCharges') {

        const getValueOrZero = (value) => {
            const parsedValue = parseFloat(value);
            return (!isNaN(parsedValue) && value !== null && value !== undefined) ? parsedValue : 0;
        };

       

        //console.log('getValueOrZeroAfter: ' + JSON.stringify(getValueOrZero));

        var allChargeDetails = this.chargeDetails[this.selectedPricingPlan];
        //console.log(':: allChargeDetails : ' + JSON.stringify(allChargeDetails));

        var chargeDetails = { ...allChargeDetails[chargeState] };
        //console.log(':: chargeDetails : ' + JSON.stringify(chargeDetails));


        // Agreement Value Present
        if (this.selectedPricingPlan == this.STANDARD_PLAN) {
            var agreementValue = chargeDetails.agreementValue;
            var otherChargesIncludingTax = chargeDetails.otherChargesIncludingTax;
            var registrationCharges = chargeDetails.registrationCharges;
            var stampDutyPercentage = chargeDetails.stampDutyPercentage;
            var GSTPercentage = chargeDetails.GSTPercentage;
            var PSF_Rate__c = parseFloat(chargeDetails.PSF_Rate__c);

            if (agreementValue === undefined || agreementValue === null) {
                agreementValue = 0;
            }



            var stampDutyCharges = Math.round(getValueOrZero(agreementValue * getValueOrZero(stampDutyPercentage) / 100));
            stampDutyCharges = this.roundUpIfDecimalGreaterThan49(stampDutyCharges) ? this.roundUpIfDecimalGreaterThan49(stampDutyCharges) : 0;

            var GSTCharges = Math.round(getValueOrZero(agreementValue * getValueOrZero(GSTPercentage) / 100)) ? Math.round(getValueOrZero(agreementValue * getValueOrZero(GSTPercentage) / 100)) : 0;
            var carParkCharges = chargeState === 'modifiedCharges' ? this.totalCarParkAmount : 0;

            // Calculate the 'All In Price' based on above values
            var TotalAllInPrice = Math.round(getValueOrZero(agreementValue)) +
                Math.round(getValueOrZero(otherChargesIncludingTax)) +
                Math.round(getValueOrZero(registrationCharges)) +
                Math.round(getValueOrZero(stampDutyCharges)) +
                Math.round(getValueOrZero(GSTCharges)) +
                Math.round(getValueOrZero(carParkCharges));

            if (chargeState == 'modifiedCharges') {
               
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.allInPrice = TotalAllInPrice;
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue = agreementValue;
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.PSF_Rate__c = PSF_Rate__c;
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.stampDutyCharges = stampDutyCharges;
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.GSTCharges = GSTCharges;
                if (this.getDiffArea > 0) {
                    this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue = (this.chargeDetails[this.selectedPricingPlan].modifiedCharges.PSF_Rate__c * this.getDiffArea) || 0;
                    console.log('updatedav: ' + this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue);

                    this.chargeDetails[this.selectedPricingPlan].modifiedCharges.allInPrice = Math.round(getValueOrZero(this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue)) +
                        Math.round(getValueOrZero(otherChargesIncludingTax)) +
                        Math.round(getValueOrZero(registrationCharges)) +
                        Math.round(getValueOrZero(stampDutyCharges)) +
                        Math.round(getValueOrZero(GSTCharges)) +
                        Math.round(getValueOrZero(carParkCharges));
                        this.getBillAmount = (this.chargeDetails[this.selectedPricingPlan].modifiedCharges.PSF_Rate__c * this.getDiffArea) || 0;
                        if(this.getBillAmount < 0){
                            this.getBillAmount = Math.abs(this.getBillAmount);
                        }
                        
                        

                }else{
                    this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue = 0;
                    this.chargeDetails[this.selectedPricingPlan].modifiedCharges.stampDutyCharges = 0;
                    this.chargeDetails[this.selectedPricingPlan].modifiedCharges.GSTCharges = 0;
                    this.chargeDetails[this.selectedPricingPlan].modifiedCharges.allInPrice =  Math.round(getValueOrZero(registrationCharges)) + Math.round(getValueOrZero(carParkCharges)) + Math.round(getValueOrZero(otherChargesIncludingTax));
                    this.getBillAmount = (this.chargeDetails[this.selectedPricingPlan].modifiedCharges.PSF_Rate__c * this.getDiffArea) || 0;
                    if(this.getBillAmount < 0){
                        this.getBillAmount = Math.abs(this.getBillAmount);
                    }

                }


                if (this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue <= 0) {
                    this.showPaymentScheduleData = false;
                } else {
                    this.showPaymentScheduleData = true;
                }

            }


            if (chargeState == 'originalCharges') {
                this.chargeDetails[this.selectedPricingPlan].originalCharges.allInPrice = TotalAllInPrice;
                this.chargeDetails[this.selectedPricingPlan].originalCharges.agreementValue = agreementValue;
                this.chargeDetails[this.selectedPricingPlan].originalCharges.PSF_Rate__c = PSF_Rate__c;
                this.chargeDetails[this.selectedPricingPlan].originalCharges.stampDutyCharges = stampDutyCharges;
                this.chargeDetails[this.selectedPricingPlan].originalCharges.GSTCharges = GSTCharges;
                if (this.getDiffArea > 0) {
                    this.chargeDetails[this.selectedPricingPlan].originalCharges.agreementValue = (this.chargeDetails[this.selectedPricingPlan].originalCharges.PSF_Rate__c * this.getDiffArea) || 0;
                    console.log('updatedav: ' + this.chargeDetails[this.selectedPricingPlan].originalCharges.agreementValue);

                    this.chargeDetails[this.selectedPricingPlan].originalCharges.allInPrice = Math.round(getValueOrZero(this.chargeDetails[this.selectedPricingPlan].originalCharges.agreementValue)) +
                        Math.round(getValueOrZero(otherChargesIncludingTax)) +
                        Math.round(getValueOrZero(registrationCharges)) +
                        Math.round(getValueOrZero(stampDutyCharges)) +
                        Math.round(getValueOrZero(GSTCharges)) +
                        Math.round(getValueOrZero(carParkCharges));
                        this.getBillAmount = (this.chargeDetails[this.selectedPricingPlan].originalCharges.PSF_Rate__c * this.getDiffArea) || 0;
                        if(this.getBillAmount < 0){
                            this.getBillAmount = Math.abs(this.getBillAmount);
                        }

                }else{
                    this.chargeDetails[this.selectedPricingPlan].originalCharges.agreementValue = 0;
                    this.chargeDetails[this.selectedPricingPlan].originalCharges.stampDutyCharges = 0;
                    this.chargeDetails[this.selectedPricingPlan].originalCharges.GSTCharges = 0;
                    this.chargeDetails[this.selectedPricingPlan].originalCharges.allInPrice = Math.round(getValueOrZero(registrationCharges)) + Math.round(getValueOrZero(carParkCharges)) + Math.round(getValueOrZero(otherChargesIncludingTax));
                    this.getBillAmount = (this.chargeDetails[this.selectedPricingPlan].originalCharges.PSF_Rate__c * this.getDiffArea) || 0;
                    if(this.getBillAmount < 0){
                        this.getBillAmount = Math.abs(this.getBillAmount);
                    }

                   

                }


            }
        }
        console.log('after calculation : ' + JSON.stringify(this.chargeDetails));



        // if (this.selectedPricingPlan == this.BOX_PLAN) {
        //     var allInPriceValue = chargeDetails.allInPrice;
        //     var otherChargesIncludingTax = chargeDetails.otherChargesIncludingTax;
        //     var registrationCharges = chargeDetails.registrationCharges;
        //     var stampDutyPercentage = chargeDetails.stampDutyPercentage;
        //     var GSTPercentage = chargeDetails.GSTPercentage;
        //     var PSF_Rate__c = parseFloat(chargeDetails.PSF_Rate__c);

        //     var carParkCharges = chargeState === 'modifiedCharges' ? this.totalCarParkAmount : 0;

        //     var agreementValueWithGSTAndStampDutyCharges = getValueOrZero(allInPriceValue) -
        //         getValueOrZero(otherChargesIncludingTax) -
        //         getValueOrZero(registrationCharges) -
        //         getValueOrZero(carParkCharges);

        //     var agreementValue = Math.round(
        //         (agreementValueWithGSTAndStampDutyCharges) /
        //         (
        //             1 +
        //             getValueOrZero(stampDutyPercentage) / 100 +
        //             getValueOrZero(GSTPercentage) / 100
        //         )
        //     );
        //     chargeDetails.agreementValue = agreementValue; // Update agreement value

        //     var stampDutyCharges = getValueOrZero(agreementValue) * getValueOrZero(stampDutyPercentage) / 100;
        //     stampDutyCharges = this.roundUpIfDecimalGreaterThan49(stampDutyCharges);

        //     var GSTCharges = getValueOrZero(agreementValue) * getValueOrZero(GSTPercentage) / 100;
        //     GSTCharges = Math.round(GSTCharges);

        //     if (chargeState === 'modifiedCharges') {
        //         this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue = agreementValue;
        //     }
        //     if (chargeState === 'originalCharges') {
        //         this.chargeDetails[this.selectedPricingPlan].originalCharges.agreementValue = agreementValue;
        //     }
        //     console.log('after calculation BOX: ' + JSON.stringify(this.chargeDetails));
        // }
    }

    handleDiffAreaCal() {
        console.log('Inside Diff Calculation');
        console.log('isQuotationOpenfromAccount:', this.isQuotationOpenfromAccount);
        console.log('unit:', JSON.stringify(this.unit));
        console.log('fetchOpp:', JSON.stringify(this.fetchOpp));

        if (this.isQuotationOpenfromAccount) {
            const totalCarpetArea = this.unit.Total_carpet_Sq_Ft__c || 0;
            const finalCommittedArea = this.fetchOpp.Final_Committed_Area__c || 0;
            const differentialCarpetArea = totalCarpetArea - finalCommittedArea;

            console.log('Total Carpet Area:', totalCarpetArea);
            console.log('Final Committed Area:', finalCommittedArea);
            console.log('Differential Carpet Area:', differentialCarpetArea);

            this.getDiffArea = differentialCarpetArea;
        } else {
            console.log('Quotation is not open from Account, setting Differential Carpet Area to 0.');
            this.getDiffArea = 0;
        }
    }




    @wire(getObjectInfo, { objectApiName: Other_Charges__c })
    otherChargesInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$otherChargesInfo.data.defaultRecordTypeId',
        fieldApiName: Charge_Type__c
    })
    handleChargeTypePicklistValues({ error, data }) {
        if (data) {
            this.otherCharges.metadata.availableOtherChargeTypes = data.values.map(value => {
                return { 'label': value.label, 'value': value.label };
            });
            console.log('this.otherCharges.metadata.availableOtherChargeTypes : ' + JSON.stringify(this.otherCharges));
        }
        if (error) {
            console.log('Error in getting picklist values for Charge Type' + JSON.stringify(error));
        }
    }

    handleOppData() {
        this.showSpinner = true;
        getOppDetails({ oppId: this.oppId })
            .then(result => {
                console.log('result: ' + JSON.stringify(result));
                this.fetchOpp = result;
                this.originalFinalCommittedArea = this.fetchOpp.Final_Committed_Area__c;
                this.error = undefined;
                if (this.fetchOpp.Project__c != undefined) {
                    this.storeProjectId = this.fetchOpp.Project__c;
                    this.handleUnitData();
                    this.showSpinner = false;
                    // this.showCustomToast('success', 'This is a success message!', 5000000); // Shows for 5 seconds

                }
            })
            .catch(error => {
                this.error = error;
                this.fetchOpp = undefined;
            })
    }

    async callCurrency(amount) {
        const result = await currencyFormat({ amt: parseFloat(amount) });
        console.log('format: ' + JSON.stringify(result));
        return result;
    }

    get getPSFAmount() {
        return this.getCurrencyInFormatted(this.unit.PSF__c, false);
    }

    get getSave() {
        return (!this.isQuotationOpenfromAccount && this.showPaymentScheduleData) ||
            (this.isQuotationOpenfromAccount && !this.showCalculate && this.selectedPricingPlan !== '' && this.selectedPaymentScheme !== '');

    }


    handleUnitData() {
        this.showSpinner = true;
        getUnitDetails({ unitId: this.uId })
            .then(result => {
                console.log('unit: ' + JSON.stringify(result));
                this.unit = result;
                this.error = undefined;
                this.getQWrapper();
                this.getPaymentScheme();

                //this.getAllPriceMap();
                this.getMilestoneType();
                this.getAmountType();
                this.getCarPark();
                this.handleDiffAreaCal();

                this.showSpinner = false;

            })
            .catch(error => {
                this.error = error;
                this.fetchOpp = undefined;
            })

        // Get the Other Charges from Unit
        this.fetchOtherCharges();

    }




    // Get the Other Charges from Unit
    fetchOtherCharges() {
        this.showSpinner = true
        getOtherCharges({ unitID: this.uId })
            .then(data => {
                if (data != null) {

                    // Initialize Other Charges
                    this.otherCharges = {
                        ...this.otherCharges,
                        'data': {}
                    };

                    // Store other charges
                    data.map((otherCharge, index) => {

                        var otherChargeType = otherCharge.Charge_Type__c;
                        var otherChargeData = {
                            'id': otherCharge.Id,
                            'sequenceNo': index + 1,
                            'chargeName': otherCharge.Charge_Type__c,
                            'chargeAmount': otherCharge.Charge_Amount__c,
                            'GSTPercentage': otherCharge.GST_Percentage__c,
                            'chargeAmountIncludingGST': otherCharge.Charge_Amount_Including_GST__c,
                            'availableOtherChargeTypes': []
                        }

                        this.otherCharges.data[otherChargeType] = otherChargeData;
                        this.updateAvailableOtherChargeTypeOptions();
                        console.log('this.otherCharges :' + JSON.stringify(this.otherCharges));
                    })

                    console.log('this.otherCharges :' + JSON.stringify(this.otherCharges));
                }
                else {
                    console.log('getOtherCharges() from apex returned unexpected data');
                }
                this.showSpinner = false;
            })
            .catch(error => {
                console.log('Internal Error : ' + error);
                this.showCustomToast(
                    'Error',
                    'Some internal error occurred while retriving Other Charge Details',
                    'Error',
                    2000
                );
                this.showSpinner = false;
            })
    }


    getQWrapper() {
        getQuotationWrapper({ unit: this.unit }).then(result => {
            if (result) {
                this.QuotationWrapper = result;
                console.log('QuotationWrapper: ' + JSON.stringify(this.QuotationWrapper));
            }
        })
            .catch(error => {
                this.error = error;
                this.QuotationWrapper = undefined;
            })
    }

    handleQuotationWrapper(event) {
        const fieldName = event.target ? event.target.fieldName : event.detail ? event.detail.fieldName : '';
        let value = event.target ? event.target.value : event.detail ? event.detail.value : '';

        // Validate all numeric fields
        const numericFields = ['All_in_Price__c', 'Total_Other_Charges__c', 'Registration_Charges__c', 'Stamp_Duty_Percentage__c', 'GST__c'];

        // Check if the field is numeric and if the value is not valid
        if (numericFields.includes(fieldName)) {

            // If value is NaN, empty, or null, set it to 0
            if (isNaN(value) || value === '' || value === null) {
                console.log('insideNaN for field: ' + fieldName);
                alert('Please Provide Valid Input');
                value = 0; // Assign 0 to the invalid numeric field
            } else {
                value = parseFloat(value); // Ensure the value is a number
            }
        }


        //const value = event.target ? event.target.checked : event.detail ? event.detail.checked : false; // Use 'checked' instead of 'value'

        if (fieldName === 'Referal_Discount__c') {
            // this.QuotationWrapper.q.Referal_Discount__c = event.target.checked;
            this.getQuotationWrapperList = {
                ...this.QuotationWrapper.q,
                [fieldName]: event.target.checked
            };
        } else {
            this.getQuotationWrapperList = {
                ...this.QuotationWrapper.q,
                [fieldName]: value
            };
        }

        this.QuotationWrapper = { q: this.getQuotationWrapperList };
        console.log('quotation Wrapper: ' + JSON.stringify(this.QuotationWrapper));
        //if (this.QuotationWrapper.q.GST__c !== '' && this.QuotationWrapper.q.All_in_Price__c !== '' && this.QuotationWrapper.q.Stamp_Duty_Percentage__c !== '') {
        //this.getAllPriceMap();
        //newCommented this.calculateModifiedValues();
        //this.updatePaymentSchedule();
        //newCommented this.getUpdatedPaymentSchedule();
        //}
        if (value != undefined && value >= 0) {
            this.showCalculate = true;
        } else {
            this.showCalculate = false;
        }

    }

    handlecalculateValues() {
        this.showCalculate = false;
        this.handleDiffAreaCal();


        // Update ChargeDetails with New charges
        this.chargeDetails[this.selectedPricingPlan].modifiedCharges = {
            ...this.chargeDetails[this.selectedPricingPlan].modifiedCharges,
            ...this.chargeDetails[this.selectedPricingPlan].newCharges
        }

        if (this.isQuotationOpenfromAccount) {
            this.calculateChargeDetailsTenantWise('originalCharges');
            this.calculateChargeDetailsTenantWise('modifiedCharges');
            this.calculateTotalOtherCharges();
            if (this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue > 0) {
                this.getPaymentSchedule();
            }
        } else {
            this.calculateChargeDetails('originalCharges');
            this.calculateChargeDetails('modifiedCharges');
            this.calculateTotalOtherCharges();
            this.getPaymentSchedule();

        }

    }

    getCarPark() {
        getCarParkDetails({ pId: this.unit.Project__c, tId: this.unit.Tower__c })
            .then(data => {
                if (data) {
                    console.log('carParkList: ' + JSON.stringify(data));
                    this.carParkList = data;
                    this.updatedCarParkList = data;
                }
            })
    }

    handlePaymentSchemeChange(event) {
        // this.isSpinner = true;
        // this.showTable = true;
        this.selectedPaymentScheme = event.target.value;
        this.selectedPaymentSchemeName = this.paymentSchemeList.find(option => option.value === this.selectedPaymentScheme).label;
        // this.isPaymentScheduleEnable = this.paymentSchemeList.find(option => option.value === this.selectedPaymentScheme).isEditable;
        // this.showPaymentScheduleData = true;
        //this.getAllPriceMap();
        // setTimeout(() => {
        //     this.calculateOriginalValues();
        //     this.calculateModifiedValues();
        //     this.getPaymentSchedule();
        //this.fomratAll();
        //     this.showTable = true;
        //this.isSpinner = false; // Show table after calculations
        // }, 0);
        // this.calculateOriginalValues();
        // this.calculateModifiedValues();

    }

    handlePricingPlanChange(event) {

        // Save selected pricing plan
        const pricingPlan = event.target.value;
        this.pricingPlanOptions.map(option => {
            if (option.value != undefined && option.value == pricingPlan) {
                this.selectedPricingPlan = option.value;
            }
        })

        // Fetch the Charge Details
        this.fetchChargeDetails();
        this.fetchOtherCharges();

    }

    handleAppliedDiscount(event) {
        var _appliedDiscount = event.target.value;

        if (_appliedDiscount != null && _appliedDiscount != undefined && _appliedDiscount > 0) {
            this.appliedDiscount = _appliedDiscount;
        }
    }

    // Retrives the Charge Details
    fetchChargeDetails() {

        this.isSpinner = true;

        getChargeDetails({ unitID: this.uId })
            .then(data => {

                console.log('fetchChargeDetails -> data : ' + JSON.stringify(data));
                if (data == undefined || data == null && Object.keys(data).length <= 0) {
                    this.showCustomToast('Error', 'Invalid data received from Server, please contact System Administrator !', 'Error', 5000);
                    this.isSpinner = false;
                    return;
                }

                // Clean Up existing charge details
                this.chargeDetails = {};

                // Quotation Type
                const quotationType = this.selectedPricingPlan;

                // Collect Charges 
                var pricingPlanChargeMap = {};
                Object.keys(data).map(chargeName => {

                    const chargeValue = data[chargeName];
                    pricingPlanChargeMap[chargeName] = chargeValue;

                    console.log('chargeName : ' + chargeName);
                    console.log('chargeValue : ' + chargeValue);
                })
                if (this.selectedPricingPlan == this.BOX_PLAN) {
                    pricingPlanChargeMap['agreementValue'] = null;
                    pricingPlanChargeMap['stampDutyCharges'] = null;
                    pricingPlanChargeMap['GSTCharges'] = null;
                    if (this.isQuotationOpenfromAccount) {
                        pricingPlanChargeMap['PSF_Rate__c'] = null;
                        pricingPlanChargeMap['PSF_Rate__c'] = this.unit.PSF_Rate__c ? parseFloat(this.unit.PSF_Rate__c) : 0;
                    }
                }
                if (this.selectedPricingPlan == this.STANDARD_PLAN) {
                    pricingPlanChargeMap['allInPrice'] = null;
                    pricingPlanChargeMap['stampDutyCharges'] = null;
                    pricingPlanChargeMap['GSTCharges'] = null;
                    if (this.isQuotationOpenfromAccount) {
                        pricingPlanChargeMap['PSF_Rate__c'] = null;
                        pricingPlanChargeMap['PSF_Rate__c'] = this.unit.PSF_Rate__c ? parseFloat(this.unit.PSF_Rate__c) : 0;
                    }
                }

                // Store Charge Details
                var originalCharges = pricingPlanChargeMap;
                var modifiedCharges = { ...pricingPlanChargeMap };  // Initializing with originalCharges

                if (this.chargeDetails[quotationType] == undefined) {
                    this.chargeDetails[quotationType] = {
                        'originalCharges': {},
                        'modifiedCharges': {},
                        'newCharges': {}
                    }
                }

                this.chargeDetails[quotationType]['originalCharges'] = originalCharges;
                this.chargeDetails[quotationType]['modifiedCharges'] = modifiedCharges;

                console.log('this.chargeDetails -> ' + JSON.stringify(this.chargeDetails));

                // After retrieving calculate the charges and show the page


                if (this.isQuotationOpenfromAccount) {
                    this.calculateChargeDetailsTenantWise('originalCharges');
                    this.calculateChargeDetailsTenantWise('modifiedCharges');
                    if (this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue > 0) {
                        this.getPaymentSchedule();
                        this.showTable = true;
                        this.isPaymentScheduleEnable = true;
                        this.isSpinner = false;
                    } else if (this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue < 0) {
                        console.log('Agreement Value is negative:', this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue);
                        this.showTable = true;
                        this.isSpinner = false;
                    } else {
                        this.showTable = true;
                        this.isSpinner = false;
                    }
                } else {
                    this.calculateChargeDetails('originalCharges');
                    this.calculateChargeDetails('modifiedCharges');
                    this.getPaymentSchedule();
                    this.showPaymentScheduleData = true;
                    this.showTable = true;
                    this.isPaymentScheduleEnable = true;
                    this.isSpinner = false;
                }


            })
            .catch(error => {
                console.log('fetchChargeDetails -> error : ' + JSON.stringify(error));
                this.showCustomToast('Error', error.body.message, 'Error in fetching charge details', 5000);
                this.isSpinner = false;
            })

    }

    // Handle Charge Details Change
    handleChargeDetailsChange(event) {

        var chargeName = event.target.dataset.chargeName;
        var chargeValue = event.target.value;

        console.log(chargeName);
        console.log(chargeValue);

        if (chargeName == 'PSF_Rate__c' && (chargeValue == undefined || chargeValue == null)) {
            chargeValue = 0;
        }
        else {
            chargeValue = parseFloat(chargeValue);
        }

        // Get new charges
        var _newCharges = {
            ...this.chargeDetails[this.selectedPricingPlan].newCharges
        }
        _newCharges[chargeName] = chargeValue;

        // Update new charges
        this.chargeDetails[this.selectedPricingPlan].newCharges = { ..._newCharges };

        console.log('this.chargeDetails : ' + JSON.stringify(this.chargeDetails));

        if (chargeValue != undefined && chargeValue >= 0) {
            this.showCalculate = true;
        } else {
            this.showCalculate = false;
        }

    }

    getPaymentScheme() {
        getPaymentSchemeDetails({ tId: this.unit.Tower__c })
            .then(data => {
                if (data) {
                    console.log('paymentSchemeList: ' + JSON.stringify(data));
                    let array = [];
                    for (let i = 0; i < data.length; i++) {
                        array.push({ label: data[i].Name, value: data[i].Id, isEditable: data[i].Is_Editable__c });
                    }
                    this.paymentSchemeList = array;
                }
            })
            .catch(error => {
                console.log('Some error occured : ' + JSON.stringify(error));

            })
    }

    handleChange(event) {
        // this.isSpinner = true;
        var index = parseInt(event.target.dataset.index);
        console.log('index: ' + index);
        var eventName = event.currentTarget.name;
        console.log('name: ' + eventName);

        if (eventName === 'carParkRequiredCount' || eventName === 'carParkAmount') {
            var value = parseInt(event.target.value);
            console.log('value: ' + value);
            //console.log('Available Count: '+this.updatedCarParkList[index].carParkAvailableCount);

            if (isNaN(value)) {
                value = 0;
            }
            if (eventName === 'carParkRequiredCount' && this.updatedCarParkList[index].carParkAvailableCount < value) {
                this.showCustomToast('Warning', 'You are not allowed to apply more car parks than the available count.');
                event.target.value = this.updatedCarParkList[index].carParkRequiredCount;
                // this.isSpinner = false;
                return;
            } else if (value < 0) {
                this.showCustomToast('Warning', 'Please provide valid details.');
                if (eventName === 'carParkRequiredCount') {
                    event.target.value = this.updatedCarParkList[index].carParkRequiredCount;
                }
                else if (eventName === 'carParkAmount') {
                    event.target.value = this.updatedCarParkList[index].carParkAmount;
                }
                return;
            } else {
                const carParkObj = { ...this.carParkList[index], [eventName]: value };
                this.carParkList = [...this.carParkList];
                this.carParkList[index] = carParkObj;

                const newObj = { ...this.updatedCarParkList[index], [eventName]: value };
                this.updatedCarParkList = [...this.updatedCarParkList];
                this.updatedCarParkList[index] = newObj;

                this.totalCarParkAmount = 0;
                this.totalCarParkCount = 0;
                console.log('this.updatedCarParkList : ' + JSON.stringify(this.updatedCarParkList));
                this.updatedCarParkList.forEach(element => {
                    console.log('Test: ' + element.carParkRequiredCount);
                    this.totalCarParkAmount += (element.carParkAmount * element.carParkRequiredCount);
                    this.totalCarParkCount  += element.carParkRequiredCount;
                    this.QuotationWrapper.q.Car_Park_Amount__c = this.totalCarParkAmount;
                    this.handleCarParkCalculation();
                })
                this.isQuotationModified = true;

                this.showCalculate = true;
            }
        } else if (eventName === 'milestoneName') {
            var value = event.target.value;
            console.log('value: ' + value);

            const newObj = { ...this.updatedPaymentMilestoneWrapperList[index], [eventName]: value };
            newObj.pm.Milestone_Name__c = value;
            this.updatedPaymentMilestoneWrapperList = [...this.updatedPaymentMilestoneWrapperList];
            this.updatedPaymentMilestoneWrapperList[index] = newObj;
            console.log('milestoneName 1: ' + this.updatedPaymentMilestoneWrapperList[index].milestoneName);
            console.log('Milestone_Name__c 1: ' + this.updatedPaymentMilestoneWrapperList[index].pm.Milestone_Name__c);

            const pmObj = { ...this.paymentMilestoneWrapperList[index], [eventName]: value };
            pmObj.pm.Milestone_Name__c = value;
            this.paymentMilestoneWrapperList = [...this.paymentMilestoneWrapperList];
            this.paymentMilestoneWrapperList[index] = pmObj;
            console.log('milestoneName 2: ' + this.paymentMilestoneWrapperList[index].milestoneName);
            console.log('Milestone_Name__c 2: ' + this.paymentMilestoneWrapperList[index].pm.Milestone_Name__c);
            //this.isSpinner = false;
        } else if (eventName === 'Number_of_Days__c') {
            var value = parseInt(event.target.value);
            console.log('value: ' + value);

            if (isNaN(value)) {
                value = null;
            }

            const newObj = { ...this.updatedPaymentMilestoneWrapperList[index].pm, [eventName]: value };
            this.updatedPaymentMilestoneWrapperList = [...this.updatedPaymentMilestoneWrapperList];
            this.updatedPaymentMilestoneWrapperList[index].pm = newObj;
            console.log('Number_of_Days__c 1: ' + this.updatedPaymentMilestoneWrapperList[index].pm.Number_of_Days__c);

            const pmObj = { ...this.paymentMilestoneWrapperList[index].pm, [eventName]: value };
            this.paymentMilestoneWrapperList = [...this.paymentMilestoneWrapperList];
            this.paymentMilestoneWrapperList[index].pm = pmObj;
            console.log('Number_of_Days__c 2: ' + this.paymentMilestoneWrapperList[index].pm.Number_of_Days__c);
            // this.isSpinner = false;
        } else if (eventName === 'Milestone_Type__c') {
            var value = event.target.value;
            console.log('value: ' + value);

            const newObj = { ...this.updatedPaymentMilestoneWrapperList[index].pm, [eventName]: value };
            this.updatedPaymentMilestoneWrapperList = [...this.updatedPaymentMilestoneWrapperList];
            this.updatedPaymentMilestoneWrapperList[index].pm = newObj;
            console.log('Milestone_Type__c 1: ' + this.updatedPaymentMilestoneWrapperList[index].pm.Milestone_Type__c);

            const pmObj = { ...this.paymentMilestoneWrapperList[index].pm, [eventName]: value };
            this.paymentMilestoneWrapperList = [...this.paymentMilestoneWrapperList];
            this.paymentMilestoneWrapperList[index].pm = pmObj;
            console.log('Milestone_Type__c 2: ' + this.paymentMilestoneWrapperList[index].pm.Milestone_Type__c);
            if (value === 'Construction Linked') {
                this.paymentMilestoneWrapperList[index].isConStructionLinked = true;
                this.updatedPaymentMilestoneWrapperList[index].pm.Construction_Stage__c = null;
            } else {
                this.paymentMilestoneWrapperList[index].isConStructionLinked = false;
                this.updatedPaymentMilestoneWrapperList[index].pm.Construction_Stage__c = null;
            }
            //this.isSpinner = false;
        } else if (eventName === 'Construction_Stage__c') {
            var value = event.target.value;
            console.log('value: ' + value);

            const newObj = { ...this.updatedPaymentMilestoneWrapperList[index].pm, [eventName]: value };
            this.updatedPaymentMilestoneWrapperList = [...this.updatedPaymentMilestoneWrapperList];
            this.updatedPaymentMilestoneWrapperList[index].pm = newObj;
            console.log('Construction_Stage__c 1: ' + this.updatedPaymentMilestoneWrapperList[index].pm.Construction_Stage__c);

            const pmObj = { ...this.paymentMilestoneWrapperList[index].pm, [eventName]: value };
            this.paymentMilestoneWrapperList = [...this.paymentMilestoneWrapperList];
            this.paymentMilestoneWrapperList[index].pm = pmObj;
            console.log('Construction_Stage__c 2: ' + this.paymentMilestoneWrapperList[index].pm.Construction_Stage__c);
            //this.isSpinner = false;
        } else if (eventName === 'Charge_Bucket_1_Type__c') {
            var value = event.target.value;
            console.log('value: ' + value);

            const newObj = { ...this.updatedPaymentMilestoneWrapperList[index].psm, [eventName]: value };
            this.updatedPaymentMilestoneWrapperList = [...this.updatedPaymentMilestoneWrapperList];
            this.updatedPaymentMilestoneWrapperList[index].psm = newObj;
            console.log('Charge_Bucket_1_Type__c 1: ' + this.updatedPaymentMilestoneWrapperList[index].psm.Charge_Bucket_1_Type__c);

            const pmObj = { ...this.paymentMilestoneWrapperList[index].psm, [eventName]: value };
            this.paymentMilestoneWrapperList = [...this.paymentMilestoneWrapperList];
            this.paymentMilestoneWrapperList[index].psm = pmObj;
            console.log('Charge_Bucket_1_Type__c 2: ' + this.paymentMilestoneWrapperList[index].psm.Charge_Bucket_1_Type__c);
            if (value === 'Amount') {
                this.paymentMilestoneWrapperList[index].isPercentage = false;
                this.paymentMilestoneWrapperList[index].isAmount = true;
            } else if (value === 'Percentage') {
                this.paymentMilestoneWrapperList[index].isPercentage = true;
                this.paymentMilestoneWrapperList[index].isAmount = false;
            }
            //this.isSpinner = false;
        } else if (eventName === 'Charge_Bucket_1_Percentage__c') {
            var value = parseFloat(event.target.value);
            console.log('value: ' + value);

            if (isNaN(value)) {
                value = null;
            }

            const newObj = { ...this.updatedPaymentMilestoneWrapperList[index].pm, [eventName]: value };
            this.updatedPaymentMilestoneWrapperList = [...this.updatedPaymentMilestoneWrapperList];
            this.updatedPaymentMilestoneWrapperList[index].pm = newObj;
            console.log('Charge_Bucket_1_Percentage__c 1: ' + this.updatedPaymentMilestoneWrapperList[index].pm.Charge_Bucket_1_Percentage__c);

            const pmObj = { ...this.paymentMilestoneWrapperList[index].pm, [eventName]: value };
            this.paymentMilestoneWrapperList = [...this.paymentMilestoneWrapperList];
            this.paymentMilestoneWrapperList[index].pm = pmObj;
            console.log('Charge_Bucket_1_Percentage__c 2: ' + this.paymentMilestoneWrapperList[index].pm.Charge_Bucket_1_Percentage__c);
            //this.isSpinner = false;
        } else if (eventName === 'Charge_Bucket_1_Amount__c') {
            var value = parseFloat(event.target.value);
            console.log('value: ' + value);

            if (isNaN(value)) {
                value = null;
            }

            const newObj = { ...this.updatedPaymentMilestoneWrapperList[index].pm, [eventName]: value };
            this.updatedPaymentMilestoneWrapperList = [...this.updatedPaymentMilestoneWrapperList];
            this.updatedPaymentMilestoneWrapperList[index].pm = newObj;
            console.log('Charge_Bucket_1_Amount__c 1: ' + this.updatedPaymentMilestoneWrapperList[index].pm.Charge_Bucket_1_Amount__c);

            const pmObj = { ...this.paymentMilestoneWrapperList[index].pm, [eventName]: value };
            this.paymentMilestoneWrapperList = [...this.paymentMilestoneWrapperList];
            this.paymentMilestoneWrapperList[index].pm = pmObj;
            console.log('Charge_Bucket_1_Amount__c 2: ' + this.paymentMilestoneWrapperList[index].pm.Charge_Bucket_1_Amount__c);
            //this.isSpinner = false;
        } else if (eventName === 'add') {
            this.actionType = 'Add';
            this.rowIndex = index;
            this.getModifiedPaymentSchedule();
        } else if (eventName === 'remove') {
            this.actionType = 'Remove';
            this.rowIndex = index;
            this.getModifiedPaymentSchedule();
        }
        if (eventName === 'milestoneName' || eventName === 'Charge_Bucket_1_Amount__c' || eventName === 'Number_of_Days__c' || eventName === 'Milestone_Type__c' ||
            eventName === 'Construction_Stage__c' || eventName === 'Charge_Bucket_1_Type__c' || eventName === 'Charge_Bucket_1_Percentage__c' || eventName === 'add' || eventName === 'remove') {
            this.showConfirm = false;
        }
    }

    async handleCarParkCalculation() {
        if (this.totalCarParkAmount > 0) {
            this.totalCarParkAmountString = await this.callCurrency(this.totalCarParkAmount);
            console.log('Car Park Amount::' + this.totalCarParkAmountString);
        } else {
            this.totalCarParkAmountString = '0.00/-';
        }
    }


    // Calculate the original/modified charge details
    // TODO : Need to review rounding up logic 
    calculateChargeDetails(chargeState = 'modifiedCharges') {

        const getValueOrZero = (value) => value !== undefined && value !== null ? parseFloat(value) || 0 : 0;

        console.log('this.selectedPricingPlan : ' + JSON.stringify(this.selectedPricingPlan));
        console.log('this.allChargeDetails : ' + JSON.stringify(this.chargeDetails));

        // Both Modified AND ORIGINAL
        var allChargeDetails = this.chargeDetails[this.selectedPricingPlan];
        console.log(':: allChargeDetails : ' + JSON.stringify(allChargeDetails));

        var chargeDetails = { ...allChargeDetails[chargeState] };
        console.log(':: chargeDetails : ' + JSON.stringify(chargeDetails));


        // Agreement Value Present
        if (this.selectedPricingPlan == this.STANDARD_PLAN) {
            var agreementValue = chargeDetails.agreementValue;
            var otherChargesIncludingTax = chargeDetails.otherChargesIncludingTax;
            var registrationCharges = chargeDetails.registrationCharges;
            var stampDutyPercentage = chargeDetails.stampDutyPercentage;
            var GSTPercentage = chargeDetails.GSTPercentage;


            var stampDutyCharges = Math.round(getValueOrZero(agreementValue * getValueOrZero(stampDutyPercentage) / 100));
            stampDutyCharges = this.roundUpIfDecimalGreaterThan49(stampDutyCharges);

            var GSTCharges = Math.round(getValueOrZero(agreementValue * getValueOrZero(GSTPercentage) / 100));
            var carParkCharges = chargeState === 'modifiedCharges' ? this.totalCarParkAmount : 0;

            // Calculate the 'All In Price' based on above values
            var TotalAllInPrice = Math.round(getValueOrZero(agreementValue)) +
                Math.round(getValueOrZero(otherChargesIncludingTax)) +
                Math.round(getValueOrZero(registrationCharges)) +
                Math.round(getValueOrZero(stampDutyCharges)) +
                Math.round(getValueOrZero(GSTCharges)) +
                Math.round(getValueOrZero(carParkCharges));



            // Store All In Price
            if (chargeState == 'modifiedCharges') {
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.allInPrice = TotalAllInPrice;
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.stampDutyCharges = stampDutyCharges;
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.GSTCharges = GSTCharges;
            }
            if (chargeState == 'originalCharges') {
                this.chargeDetails[this.selectedPricingPlan].originalCharges.allInPrice = TotalAllInPrice;
                this.chargeDetails[this.selectedPricingPlan].originalCharges.stampDutyCharges = stampDutyCharges;
                this.chargeDetails[this.selectedPricingPlan].originalCharges.GSTCharges = GSTCharges;
            }
            console.log('after calcualtion : ' + JSON.stringify(this.chargeDetails));
        }

        // All In Price Present
        if (this.selectedPricingPlan == this.BOX_PLAN) {

            var allInPriceValue = chargeDetails.allInPrice;
            var otherChargesIncludingTax = chargeDetails.otherChargesIncludingTax;
            var registrationCharges = chargeDetails.registrationCharges;
            var stampDutyPercentage = chargeDetails.stampDutyPercentage;
            var GSTPercentage = chargeDetails.GSTPercentage;

            var carParkCharges = chargeState === 'modifiedCharges' ? this.totalCarParkAmount : 0;

            // Calculate the 'Base Value' / 'Agreeement Value with 'GST charges' and 'Stamp Duty Charges'
            var agreementValueWithGSTAndStampDutyCharges = getValueOrZero(allInPriceValue) -
                getValueOrZero(otherChargesIncludingTax) -
                getValueOrZero(registrationCharges) -
                getValueOrZero(carParkCharges);
            var agreementValue = Math.round(
                (agreementValueWithGSTAndStampDutyCharges) /
                (
                    1 +
                    getValueOrZero(stampDutyPercentage) / 100 +
                    getValueOrZero(GSTPercentage) / 100
                )
            );

            // Calculate Stamp Duty Charge, GST charges
            var stampDutyCharges = getValueOrZero(agreementValue) * getValueOrZero(stampDutyPercentage) / 100;
            stampDutyCharges = this.roundUpIfDecimalGreaterThan49(stampDutyCharges);

            var GSTCharges = getValueOrZero(agreementValue) * getValueOrZero(GSTPercentage) / 100;
            GSTCharges = Math.round(GSTCharges);

            // Store All In Price
            if (chargeState === 'modifiedCharges') {
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue = agreementValue;
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.stampDutyCharges = stampDutyCharges;
                this.chargeDetails[this.selectedPricingPlan].modifiedCharges.GSTCharges = GSTCharges;
            }
            if (chargeState === 'originalCharges') {
                this.chargeDetails[this.selectedPricingPlan].originalCharges.agreementValue = agreementValue;
                this.chargeDetails[this.selectedPricingPlan].originalCharges.stampDutyCharges = stampDutyCharges;
                this.chargeDetails[this.selectedPricingPlan].originalCharges.GSTCharges = GSTCharges;
            }
            console.log('after calcualtion BOX: ' + JSON.stringify(this.chargeDetails));

        }
    }

    roundUpIfDecimalGreaterThan49(value) {
        const integerPart = Math.floor(value);
        const decimalPart = value - integerPart;
        return decimalPart > 0.49 ? integerPart + 1 : integerPart;
    }



    getPaymentSchedule() {
        this.isSpinner = true;
        this.paymentMilestoneWrapperList = [];
        this.updatedPaymentMilestoneWrapperList = [];
        console.log('this.getModifiedGstAmount' + this.getModifiedGstAmount);
        console.log('this.getModifiedGstAmount' + typeof (this.getModifiedGstAmount));
        getPaymentScheduleDetails({
            uId: this.unit.Id,
            selectedScheme: this.selectedPaymentScheme,
            getModifiedAV: this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue,
            gst: this.chargeDetails[this.selectedPricingPlan].modifiedCharges.GSTPercentage,
            getModifiedGstAmount: parseInt(this.chargeDetails[this.selectedPricingPlan].modifiedCharges.GSTCharges)
        })
            .then(data => {
                if (data) {
                    console.log('paymentMilestoneWrapperList: ' + JSON.stringify(data));

                    data.forEach(element => {
                        if (element.isTotal) {
                            this.paymentMilestoneWrapperList.push({
                                ...element
                            });
                        } else {
                            var csList = [];
                            element.constructionStageList.forEach(cs => {
                                csList.push({ label: cs.Name, value: cs.Id });
                            })

                            console.log('csList zxc :' + JSON.stringify(csList));
                            console.log('element :' + JSON.stringify(element));
                            

                            this.paymentMilestoneWrapperList.push({
                                ...element,
                                milestoneType: this.milestoneType,
                                isConStructionLinked: element.pm.Milestone_Type__c === 'Construction Linked',
                                csListDisplay: csList,
                                amountType: this.amountType,
                                isAmount: element.psm.Charge_Bucket_1_Type__c === 'Amount',
                                isPercentage: element.psm.Charge_Bucket_1_Type__c === 'Percentage'
                            });
                        }
                    })
                    this.updatedPaymentMilestoneWrapperList = data;

                    for (let i = 1; i <= 5; i++) {
                        if (this.updatedPaymentMilestoneWrapperList[0].psm["Charge_Bucket_" + i + "__c"] !== "") {
                            if (this.updatedPaymentMilestoneWrapperList[0].psm["Charge_Bucket_" + i + "__c"] === 'Agreement Value') {
                                this.agSeqNumber = i;
                                break;
                            }
                        }
                    }

                    //this.isSpinner = false;
                    console.log('updatedPaymentMilestoneWrapperList: ' + JSON.stringify(this.updatedPaymentMilestoneWrapperList));
                    //console.log('updatedPaymentMilestoneWrapperList Size : '+this.updatedPaymentMilestoneWrapperList.length);
                    this.isSpinner = false;
                } else if (error) {
                    console.error('Error In getPaymentSchedule: ', error);
                    this.isSpinner = false;
                }
            })
    }

    getMilestoneType() {
        getPicklistValuesFromApex({ objectName: 'Payment_Milestone__c', picklistField: 'Milestone_Type__c' })
            .then(data => {
                if (data) {
                    console.log('dataPM: ' + JSON.stringify(data));
                    data.forEach(element => {
                        this.milestoneType.push({ label: element, value: element });
                    })
                } else if (error) {
                    console.error('Error In getMilestoneType: ', error);
                }
            })
    }

    getAmountType() {
        getPicklistValuesFromApex({ objectName: 'Payment_Scheme_Milestone__c', picklistField: 'Charge_Bucket_1_Type__c' })
            .then(data => {
                if (data) {
                    console.log('dataPSM: ' + JSON.stringify(data));
                    data.forEach(element => {
                        this.amountType.push({ label: element, value: element });
                    })
                } else if (error) {
                    console.error('Error In getAmountType: ', error);
                }
            })
    }
    getModifiedPaymentSchedule() {
        console.log('agSeqNumber: ' + this.agSeqNumber);
        getModifiedPaymentScheduleDetails({ actionType: this.actionType, rowIndex: this.rowIndex, paymentMilestoneWrapperList: this.updatedPaymentMilestoneWrapperList, u: this.unit, agSeqNumber: this.agSeqNumber })
            .then(data => {
                if (data) {
                    this.isPaymentScheduleUpdated = true;
                    this.paymentMilestoneWrapperList = [];
                    this.updatedPaymentMilestoneWrapperList = [];
                    console.log('paymentMilestoneWrapperList: ' + JSON.stringify(data));

                    data.forEach(element => {
                        if (element.isTotal) {
                            this.paymentMilestoneWrapperList.push({
                                ...element
                            });
                        } else {
                            var csList = [];
                            element.constructionStageList.forEach(cs => {
                                csList.push({ label: cs.Name, value: cs.Id });
                            })

                            this.paymentMilestoneWrapperList.push({
                                ...element,
                                milestoneType: this.milestoneType,
                                isConStructionLinked: element.pm.Milestone_Type__c === 'Construction Linked',
                                csListDisplay: csList,
                                amountType: this.amountType,
                                isAmount: element.psm.Charge_Bucket_1_Type__c === 'Amount',
                                isPercentage: element.psm.Charge_Bucket_1_Type__c === 'Percentage'
                            });
                        }
                    })
                    this.updatedPaymentMilestoneWrapperList = data;
                    //this.isSpinner = false;
                    console.log('updatedPaymentMilestoneWrapperList: ' + JSON.stringify(this.updatedPaymentMilestoneWrapperList));
                    console.log('updatedPaymentMilestoneWrapperList Size : ' + this.updatedPaymentMilestoneWrapperList.length);
                } else if (error) {
                    console.error('Error In getModifiedPaymentSchedule: ', error);
                }
            })
    }

    showPaymentSchedule() {
        this.showPaymentScheduleData = true;
        this.isShowButtonVisiable = false;
    }

    editPaymentSchedule() {
        this.editPaymentScheduleMode = true;
    }


    updatePaymentSchedule() {
        //this.isSpinner = true;
        this.isValidationError = false;
        const validationErrorList = [];
        let errorCount = 0;
        let rowCount = 1;

        var totalPercentage = 0;

        for (let i = 0; i < this.updatedPaymentMilestoneWrapperList.length; i++) {
            if (!this.updatedPaymentMilestoneWrapperList[i].isTotal) {
                if (this.updatedPaymentMilestoneWrapperList[i].milestoneName === "" || this.updatedPaymentMilestoneWrapperList[i].pm.Milestone_Name__c === "") {
                    errorCount++;
                    validationErrorList.push('Error ' + errorCount + ': On Row-' + rowCount + '- Please Provide Milestone Name.');
                }
                if (this.updatedPaymentMilestoneWrapperList[i].pm.Number_of_Days__c === null) {
                    errorCount++;
                    validationErrorList.push('Error ' + errorCount + ': On Row-' + rowCount + '- Please Provide No of Days.');
                }
                if (this.updatedPaymentMilestoneWrapperList[i].pm.Milestone_Type__c === "") {
                    errorCount++;
                    validationErrorList.push('Error ' + errorCount + ': On Row-' + rowCount + '- Please Provide Milestone Type.');
                } else if (this.updatedPaymentMilestoneWrapperList[i].pm.Milestone_Type__c !== "" && this.updatedPaymentMilestoneWrapperList[i].pm.Milestone_Type__c === 'Construction Linked') {
                    if (this.updatedPaymentMilestoneWrapperList[i].pm.Construction_Stage__c === null) {
                        errorCount++;
                        validationErrorList.push('Error ' + errorCount + ': On Row-' + rowCount + '- Please Provide Valid Construction Stage.');
                    }
                }
                if (this.updatedPaymentMilestoneWrapperList[i].psm["Charge_Bucket_" + this.agSeqNumber + "_Type__c"] === "") {
                    errorCount++;
                    validationErrorList.push('Error ' + errorCount + ': On Row-' + rowCount + '- Please Provide Amount Type.');
                } else {
                    if (this.updatedPaymentMilestoneWrapperList[i].psm["Charge_Bucket_" + this.agSeqNumber + "_Type__c"] === 'Percentage' && this.updatedPaymentMilestoneWrapperList[i].pm["Charge_Bucket_" + this.agSeqNumber + "_Percentage__c"] === null) {
                        errorCount++;
                        validationErrorList.push('Error ' + errorCount + ': On Row-' + rowCount + '- Please Provide Milestone Percentage.');
                    } else if (this.updatedPaymentMilestoneWrapperList[i].psm["Charge_Bucket_" + this.agSeqNumber + "_Type__c"] === 'Amount' && this.updatedPaymentMilestoneWrapperList[i].pm["Charge_Bucket_" + this.agSeqNumber + "_Amount__c"] === null) {
                        errorCount++;
                        validationErrorList.push('Error ' + errorCount + ': On Row-' + rowCount + '- Please Provide Milestone Amount.');
                    }
                }

                var rowPercentage = this.updatedPaymentMilestoneWrapperList[i].pm["Charge_Bucket_" + this.agSeqNumber + "_Percentage__c"];
                console.log('rowpercetntage: ' + rowPercentage);

                if (rowPercentage != undefined && rowPercentage != null) {
                    totalPercentage = parseFloat(totalPercentage) + parseFloat(rowPercentage);
                }
            }
            rowCount++;
        }

        console.log('validationErrorList-1: ' + validationErrorList);
        console.log('totalPercentage: ' + totalPercentage);
        if (parseFloat(totalPercentage) !== parseFloat(100)) {
            errorCount++;
            validationErrorList.push(`Percentage sum should be equal to 100% (currently ${totalPercentage}%)`);
        }

        if (validationErrorList.length === 0) {
            const allPriceInfoMap = new Map();
            allPriceInfoMap.set('Agreement Value', this.getModifiedAVValue);  // String key and decimal (Number) value
            validateUpdatedPaymentScheduleDetails({
                agSeqNumber: this.agSeqNumber,
                getModifiedAv: this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue,
                updatedPaymentMilestoneWrapperList: this.updatedPaymentMilestoneWrapperList
            })
                .then(data => {
                    if (data) {
                        for (let i = 0; i < data.length; i++) {
                            validationErrorList.push(data[i]);
                        }
                        console.log('validationErrorList-2: ' + validationErrorList);

                        if (validationErrorList.length === 0) {
                            this.getUpdatedPaymentSchedule();

                            this.showCustomToast('Success', 'Payment Schedule Updated Sucessfully !', 'Success', 2000);
                            this.showConfirm = true;
                        } else {
                            var errorMessage = '';
                            for (let i = 0; i < validationErrorList.length; i++) {
                                errorMessage += validationErrorList[i] + '\n';
                            }
                            console.log('errorMessage: ' + errorMessage);
                            this.showCustomToast('Error', errorMessage, 'Error');
                            //this.isSpinner = false;
                        }
                    } else if (error) {
                        console.error('Error In validatePaymentSchedule: ', error);
                    }
                })
        } else {
            var errorMessage = '';
            for (let i = 0; i < validationErrorList.length; i++) {
                errorMessage += validationErrorList[i] + '\n';
            }
            console.log('errorMessage: ' + errorMessage);
            alert('Error: ' + errorMessage);
            //this.showCustomToast('Warning', errorMessage, 50000);
            //this.isSpinner = false;
        }
    }

    getUpdatedPaymentSchedule() {
        getUpdatedPaymentScheduleDetails({
            u: this.unit,
            agSeqNumber: this.agSeqNumber,
            getModifiedAV: this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue,
            updatedPaymentMilestoneWrapperList: this.updatedPaymentMilestoneWrapperList,
            gstAmount: parseInt(this.chargeDetails[this.selectedPricingPlan].modifiedCharges.GSTCharges),
            gstPer: this.chargeDetails[this.selectedPricingPlan].modifiedCharges.GSTPercentage
        })
            .then(data => {
                console.log('data: ' + JSON.stringify(data));
                if (data) {
                    this.isPaymentScheduleUpdated = true;
                    this.paymentMilestoneWrapperList = [];
                    this.updatedPaymentMilestoneWrapperList = [];
                    console.log('data: ' + JSON.stringify(data));

                    data.forEach(element => {
                        if (element.isTotal) {
                            this.paymentMilestoneWrapperList.push({
                                ...element
                            });
                        } else {
                            var csList = [];
                            element.constructionStageList.forEach(cs => {
                                csList.push({ label: cs.Name, value: cs.Id });
                            })

                            this.paymentMilestoneWrapperList.push({
                                ...element,
                                milestoneType: this.milestoneType,
                                isConStructionLinked: element.pm.Milestone_Type__c === 'Construction Linked',
                                csListDisplay: csList,
                                amountType: this.amountType,
                                isAmount: element.psm.Charge_Bucket_1_Type__c === 'Amount',
                                isPercentage: element.psm.Charge_Bucket_1_Type__c === 'Percentage'
                            });
                        }
                    })
                    this.updatedPaymentMilestoneWrapperList = data;
                    // this.getCalculatedNPV();
                    //this.isSpinner = false;
                } else if (error) {
                    console.error('Error In getUpdatedPaymentSchedule: ', error);
                }
            })
    }
    confirmPaymentSchedule() {
        this.editPaymentScheduleMode = false;
    }
    cancelPaymentSchedule() {
        // this.isSpinner = true;
        this.getPaymentSchedule();
        this.editPaymentScheduleMode = false;
        this.isValidationError = false;
    }
    showCustomToast(type, message, title = '', timeout = 5000) { // Timeout in milliseconds
        this.toastVariant = type;
        this.toastMessage = message;
        this.toastTitle = title;
        this.showToast = true;
        setTimeout(() => {
            this.showToast = false;
        }, timeout);
    }
    closeToast() {
        this.showToast = false;
    }

    updateQuotationWrapperDetails() {
        this.QuotationWrapper['q'] = {
            ...this.QuotationWrapper['q'],
            'Orginal_AV_Value__c': this.chargeDetails[this.selectedPricingPlan].originalCharges.agreementValue,
            'Modified_AV_Value__c': this.chargeDetails[this.selectedPricingPlan].modifiedCharges.agreementValue,
            'Total_Other_Charges_Including_Tax__c': this.chargeDetails[this.selectedPricingPlan].originalCharges.otherChargesIncludingTax,
            'Modified_Other_Charges_Including_Tax__c': this.chargeDetails[this.selectedPricingPlan].modifiedCharges.otherChargesIncludingTax,
            'Registration_Charges__c': this.chargeDetails[this.selectedPricingPlan].originalCharges.registrationCharges,
            'Modified_Registration_Charges__c': this.chargeDetails[this.selectedPricingPlan].modifiedCharges.registrationCharges,
            'Stamp_Duty_Percentage__c': this.chargeDetails[this.selectedPricingPlan].originalCharges.stampDutyPercentage,
            'Modified_Stamp_Duty__c': this.chargeDetails[this.selectedPricingPlan].modifiedCharges.stampDutyPercentage,
            'All_in_Price__c': this.chargeDetails[this.selectedPricingPlan].originalCharges.allInPrice,
            'Modified_All_in_Price__c': this.chargeDetails[this.selectedPricingPlan].modifiedCharges.allInPrice,
            'Car_Park_Amount__c': this.QuotationWrapper.q.Car_Park_Amount__c,
            'Car_Park_Required_Count__c': this.totalCarParkCount,
            'Original_Final_Committed_Area__c' : this.originalFinalCommittedArea,
            'Modified_Final_Committed_Area__c' : this.fetchOpp.Final_Committed_Area__c,
            'Pricing_Plan__c': this.selectedPricingPlan == 'box' ? 'Box Plan' : this.selectedPricingPlan == 'standard' ? 'Standard Plan' : null,
            'Modified_GST__c': this.chargeDetails[this.selectedPricingPlan].modifiedCharges.GSTPercentage,
            'GST_Charges__c': this.chargeDetails[this.selectedPricingPlan].originalCharges.GSTCharges,
            'Modified_GST_Charges__c': this.chargeDetails[this.selectedPricingPlan].modifiedCharges.GSTCharges,
            'Stamp_Duty_Charges__c': this.chargeDetails[this.selectedPricingPlan].originalCharges.stampDutyCharges,
            'Modified_Stamp_Duty_Charges__c': this.chargeDetails[this.selectedPricingPlan].modifiedCharges.stampDutyCharges,
            'Applied_Discount__c': this.appliedDiscount,
            'Original_PSF_Rate__c': this.chargeDetails[this.selectedPricingPlan].originalCharges.PSF_Rate__c,
            'Modified_PSF_Rate__c': this.chargeDetails[this.selectedPricingPlan].modifiedCharges.PSF_Rate__c,
            'Differential_Carpet_Area__c': this.getDiffArea ? this.getDiffArea : 0
        }
    }

    saveQuotation() {
        this.isSpinner = true;
        this.updateQuotationWrapperDetails();
       
        //console.log('_otherCharges: ' + JSON.stringify(_otherCharges));

        if(this.isQuotationOpenfromAccount && (this.getChargeDetailsData.PSF_Rate__c === null || this.getChargeDetailsData.PSF_Rate__c <= 0)){
            this.showCustomToast('Error', 'PSF Rate cannot be zero', 'Error', 5000);
            this.isSpinner = false;
            return;
        }
        if(this.isQuotationOpenfromAccount && (this.fetchOpp.Final_Committed_Area__c === null || this.fetchOpp.Final_Committed_Area__c <= 0)){
            this.showCustomToast('Error', 'Final Commited Area cannot be zero', 'Error', 5000);
            this.isSpinner = false;
            return;
        }
        if(this.isQuotationOpenfromAccount && this.diffDate === null && this.getDiffArea <= 0){
            this.showCustomToast('Error', 'Please Provide Bill Date', 'Error', 5000);
            this.isSpinner = false;
            return;
        }else if(this.isQuotationOpenfromAccount && this.diffDate !== null){
            this.callSave();
        }else{
            this.callSave();
        }
       
    }

    callSave(){
        console.log('inside save: '+this.getBillAmount);
        console.log('inside isQuotationOpenfromAccount: '+this.isQuotationOpenfromAccount);
        console.log('inside getDiffArea: '+this.getDiffArea);
        console.log('inside diffDate: '+this.diffDate);
        var _otherCharges = Object.values(this.otherCharges.data).map(otherCharge => {
            const { availableOtherChargeOptions, availableOtherChargeTypes, ...rest } = otherCharge;
            return rest;
        })

        


        saveQuotationDetails({
            u: this.unit,
            oppId: this.oppId,
            selectedSchemeId: this.selectedPaymentScheme,
            carParkList: this.updatedCarParkList,
            paymentMilestoneWrapperList: this.updatedPaymentMilestoneWrapperList || null,
            qWrapper: this.QuotationWrapper,
            otherCharges: _otherCharges,
            isTenantAccount: this.isQuotationOpenfromAccount,
            diDate: this.diffDate,
            BillAmount: this.getBillAmount
        }).then(data => {
            if (data) {
                console.log('data: ' + JSON.stringify(data));
                if (data !== null) {
                    console.log('Quotaion Created Successfully !');
                    this.isSpinner = false;
                    window.location.href = window.location.origin + '/' + data;
                } else {
                    console.log('Quotation Id is null');
                    this.showCustomToast('Error', 'Error Occured While Generating Quotation. Please Contact System Administrator.', 'Success', 5000);
                }
            } else if (error) {
                console.error('Error In saveQuotation: ', error);
                this.showCustomToast('Error', error.message);
            }
        })
    }


    get otherChargesList() {
        var _otherChargesList = Object.values(this.otherCharges.data) || [];
        console.log('_otherChargesList : ' + JSON.stringify(_otherChargesList));

        return {
            'data': _otherChargesList,
            'isEmpty': _otherChargesList.length == 0
        };
    }

    // Show Error/Success messages as a Toast
    showToastMessage(messageType, messageTitle, messageContent) {
        var toastMessageEvent = new ShowToastEvent({
            title: messageTitle,
            variant: messageType,
            message: messageContent
        })
        this.dispatchEvent(toastMessageEvent);
    }

    get isBoxPlan() {
        if (!this.isQuotationOpenfromAccount) {
            var status = this.selectedPricingPlan == this.BOX_PLAN;
            return status;
        }

    }
    get isStandardPlan() {
        var status = this.selectedPricingPlan == this.STANDARD_PLAN;
        return status;
    }

    // Returns the Map of charge name -  value
    // TODO : Need to revise, to add dyanmic identifier for input field.
    get getChargeDetailsData() {
        if (this.selectedPricingPlan != undefined && this.selectedPricingPlan != null && this.chargeDetails != undefined && this.chargeDetails != null) {
            var chargeDetailsData = this.chargeDetails[this.selectedPricingPlan];
            if (chargeDetailsData && chargeDetailsData.modifiedCharges) {

                // Add Dynamic Labels
                var labelledChargeDetails = {};
                // console.log('Object.keys(chargeDetailsData.modifiedCharges) : ' + chargeDetailsData.modifiedCharges);
                // console.log('Object.keys(chargeDetailsData.modifiedCharges) : ' + Object.keys(chargeDetailsData.modifiedCharges));

                Object.keys(chargeDetailsData.modifiedCharges).map(chargeName => {
                    labelledChargeDetails[chargeName] = { 'label': chargeName, 'value': chargeDetailsData.modifiedCharges[chargeName] };
                });
                // console.log('labelledChargeDetails : ' + JSON.stringify(labelledChargeDetails));

                // return formattedData;
                return chargeDetailsData.modifiedCharges;
                // return labelledChargeDetails;
            }
        }
        return {};
    }

    get getChargeDetailsDataFormatted() {
        // Convert Price value -> Formatted values

        var formattedData = {};

        if (this.selectedPricingPlan != undefined && this.selectedPricingPlan != null && this.chargeDetails != undefined && this.chargeDetails != null) {
            var chargeDetailsData = { ...this.chargeDetails[this.selectedPricingPlan] };
            if (chargeDetailsData && chargeDetailsData.modifiedCharges) {
                var dataSample = { ...chargeDetailsData.modifiedCharges };
                // console.log('dataSample : ' + JSON.stringify(dataSample));

                Object.keys(dataSample).map(chargeName => {
                    // console.log('CAHRGE NAME : ' + chargeName);
                    // console.log('CAHRGE NAME : ' + dataSample[chargeName]);
                    // console.log('CAHRGE NAME : ' + formattedData[chargeName]);

                    var name = String(chargeName);
                    var value = this.getCurrencyInFormatted(dataSample[chargeName]);

                    formattedData[name] = value;

                    return null;
                })
            }
        }

        return formattedData;
    }

    get getOriginalChargeDetailsDataFormatted() {
        // Convert Price value -> Formatted values

        var formattedData = {};

        if (this.selectedPricingPlan != undefined && this.selectedPricingPlan != null && this.chargeDetails != undefined && this.chargeDetails != null) {
            var chargeDetailsData = { ...this.chargeDetails[this.selectedPricingPlan] };
            if (chargeDetailsData && chargeDetailsData.originalCharges) {
                var dataSample = { ...chargeDetailsData.originalCharges };
                console.log('dataSample : ' + JSON.stringify(dataSample));

                Object.keys(dataSample).map(chargeName => {
                    var name = String(chargeName);
                    var value = this.getCurrencyInFormatted(dataSample[chargeName]);

                    formattedData[name] = value;

                    return null;
                })
            }
        }

        return formattedData;
    }


    // Get Currency In Formatted
    getCurrencyInFormatted(amount, includeSlash = true) {
        if (amount == undefined || amount == null || Number.isNaN(amount)) {
            return '';
        }

        const isNegative = amount < 0; // Check if the value is negative
        amount = Math.abs(amount); // Convert to positive for formatting

        // Convert to number and decimal part
        var numberInString = Number(amount).toFixed(2);
        var wholeParts = numberInString.split('.');

        var numberPart = wholeParts[0];
        var decimalPart = wholeParts[1];

        var numberPartFormatted = '';
        if (numberPart.length > 3) {
            let lastThree = numberPart.slice(-3);
            let remaining = numberPart.slice(0, -3);

            // Add commas to the remaining part of the number in groups of 2 digits
            numberPartFormatted = this.splitStringIntoParts(remaining) + ',' + lastThree;
        }
        else {
            numberPartFormatted = numberPart;
        }

        var formattedNumber = numberPartFormatted + '.' + decimalPart;
        if (includeSlash === true) {
            formattedNumber = formattedNumber + '/-';
        }

        // Add negative sign if the original amount was negative
        if (isNegative) {
            formattedNumber = '-' + formattedNumber;
        }

        return formattedNumber;
    }


    splitStringIntoParts(str) {
        let result = [];
        let length = str.length;

        if (length % 2 !== 0) {
            result.push(str[0]);
            str = str.slice(1);
        }

        for (let i = 0; i < str.length; i += 2) {
            result.push(str.substring(i, i + 2));
        }

        return result.join(',');
    }

    // --- Other Charge Calculations and Handling ---
    handleOtherChargeDetailChange(event) {

        this.showCalculate = true;

        var inputType = event.target.dataset.inputType;
        var chargeType = event.target.dataset.chargeType;
        var value = event.target.value;

        if (inputType == 'GSTPercentage') {
            this.otherCharges.data[chargeType].GSTPercentage = parseFloat(value);
        }
        if (inputType == 'chargeAmount') {
            this.otherCharges.data[chargeType].chargeAmount = parseFloat(value);
        }

        var modifiedChargeAmountIncludingGST = (
            this.otherCharges.data[chargeType].chargeAmount +
            this.otherCharges.data[chargeType].GSTPercentage * this.otherCharges.data[chargeType].chargeAmount / 100
        );
        this.otherCharges.data[chargeType].chargeAmountIncludingGST = modifiedChargeAmountIncludingGST;
    }

    // Handle Add button
    handleOtherChargeAddButtonClick(event) {

        // Validate : Check is there any existing addable charge present
        var availableOtherChargeTypes = this.otherCharges.metadata.availableOtherChargeTypes.filter(availableOtherChargeType => {
            return Object.keys(this.otherCharges.data).indexOf(availableOtherChargeType.value) == -1;
        });
        if (availableOtherChargeTypes == undefined || availableOtherChargeTypes == null || availableOtherChargeTypes.length == 0) {
            this.showCustomToast('Error', "All 'Other Charges' has been used, you cannot add more.", 'Error', 5000);
            return;
        }

        this.showCalculate = true;

        var otherChargeType = availableOtherChargeTypes[0].value;
        var otherChargeDetails = {
            'id': 'recordTypeID',
            'sequenceNo': Object.keys(this.otherCharges.data).length + 1,
            'chargeName': otherChargeType,
            'chargeAmount': 0,
            'GSTPercentage': 0,
            'chargeAmountIncludingGST': 0,
            'availableOtherChargeTypes': availableOtherChargeTypes
            // 'availableOtherChargeOptions' : availableOtherChargeTypes
        }

        var modifiedData = { ...this.otherCharges.data };
        modifiedData[otherChargeType] = otherChargeDetails;

        this.otherCharges.data = modifiedData;
        this.updateAvailableOtherChargeTypeOptions();
    }

    // Remove button handler
    handleOtherChargeRemoveButtonClick(event) {

        this.showCalculate = true;

        var otherChargeType = event.target.dataset.chargeType;
        delete this.otherCharges.data[otherChargeType];
        this.updateAvailableOtherChargeTypeOptions();

        console.log('otherChargeType : ' + JSON.stringify(otherChargeType));
    }

    // Update Options for Charges
    updateAvailableOtherChargeTypeOptions() {

        var usedOtherChargeTypeOptions = Object.keys(this.otherCharges.data);
        Object.keys(this.otherCharges.data).map((otherChargeType, index) => {

            var otherChargeData = this.otherCharges.data[otherChargeType];
            otherChargeData = {
                ...otherChargeData,
                'sequenceNo': index + 1,
                'availableOtherChargeTypes': this.otherCharges.metadata.availableOtherChargeTypes.filter(otherChargeOption => {
                    return otherChargeOption.value == otherChargeType || usedOtherChargeTypeOptions.indexOf(otherChargeOption.value) == -1
                })
            }

            this.otherCharges.data[otherChargeType] = otherChargeData;
        })
    }

    // Calculate All other charges
    calculateTotalOtherCharges() {

        var totalOtherCharges = Object.values(this.otherCharges.data).reduce(
            (total, otherCharge) => {
                console.log('total : ' + JSON.stringify(total));
                console.log('otherCharge : ' + JSON.stringify(otherCharge));
                return total + otherCharge.chargeAmountIncludingGST
            },
            0
        )
        this.chargeDetails[this.selectedPricingPlan].modifiedCharges.otherChargesIncludingTax = totalOtherCharges;
        this.calculateChargeDetails('modifiedCharges');
    }


}