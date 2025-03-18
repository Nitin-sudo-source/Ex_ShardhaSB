import { LightningElement, track, api, wire } from 'lwc';
import saveEscallations from '@salesforce/apex/Ex_RentExcallationController.createEscallationRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import OBJECT_NAME from '@salesforce/schema/Escalation__c';
import CONFIGURATION_FIELD from '@salesforce/schema/Escalation__c.Configuration__c';
import PROPERTY_TYPE_FIELD from '@salesforce/schema/Escalation__c.Property_Type__c';
import { NavigationMixin } from 'lightning/navigation';
import getTermSheet from '@salesforce/apex/Ex_RentExcallationController.getTermSheet';
export default class NavigationMixinUtility extends NavigationMixin(LightningElement) {
    @api recordId;
    @track CalculatedEndDate = null;
    @track EndDate;
    @track configurationOptions = [];
    @track propertyTypeOptions = [];
    @track selectedPropertyType = null;
    @track selectedConfiguration = [];
    @track escallationRecord = [];
    @track showRadioButton = true;
    @track isSpinner = false;
    StartDate;
    objectData;
    start_date;
    isLoaded = false;
    @track recordTypeId;
    @track termSheet;

    constructor() {
        super();
        this.isSpinner = true;
    }


    connectedCallback() {
        console.log('RECORD ID : ' + this.recordId);
    }



    @wire(getObjectInfo, { objectApiName: OBJECT_NAME })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectData = data;
            this.recordTypeId = this.objectData.defaultRecordTypeId || null;
            console.log('object info' + JSON.stringify(data));
            console.log('CONFIGURATION_FIELD ' + JSON.stringify(CONFIGURATION_FIELD));
           
        }
        else {
            console.log('Error while fetching object info' + error);
        }
    }



    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: CONFIGURATION_FIELD })
    configurationValues({ data, error }) {
        if (data) {
            console.log('Field Values ' + JSON.stringify(data));
            this.configurationOptions = data.values.map(item => ({
                label: item.label,
                value: item.value,
            }));
            console.log('this.configurationOptions ' + this.configurationOptions);
            this.onAddFirstRow();
        }

    }
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PROPERTY_TYPE_FIELD })
    propertyFieldValues({ data, error }) {
        if (data) {
            this.propertyTypeOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
            console.log('property data' + JSON.stringify(data));
            console.log('propertyTypeOptions date' + JSON.stringify(this.propertyTypeOptions));
        }
    }

    // Get Term Sheet Information
    @wire(getTermSheet, {termSheetID : "$recordId"})
    handleTermSheet({error, data}){
        if(data){
            this.termSheet = data;
            console.log('this.termSheet : ' + JSON.stringify(this.termSheet));
        }
        if(error){
            console.log('Internal Error Occurred : ' + JSON.stringify(error));
        }
    }

    renderedCallback() {
        if (this.isLoaded) return;
        const STYLE = document.createElement("style");
        STYLE.innerText = `.uiModal--medium .modal-container, .slds-modal__container{
                width: 85vw !important;
                height: 100vh !important;
                padding : 40px 0px 20px 0px !important;
                max-width : 100vw;
                min-width : 480px;
                max-height: 100vh;
                min-height: 480px;
            }`;
        this.template.querySelector('lightning-card').appendChild(STYLE);
        this.isLoaded = true;
    }


    onAddFirstRow() {

        const newRow = {
            key: this.escallationRecord.length + 1,
            Start_Date__c: null,
            Months__c: 0,
            End_Date__c: null,
            // Property_Type__c:null,
            ConfigurationOptions: this.configurationOptions,
            Configuration__c: [],
            Escalation__c: 0,
            Term_Sheet__c: this.recordId,
            disableStartDate: false,
            disableAddRow: false,
            disableRemoveRow: true,

        }

        this.escallationRecord = [...this.escallationRecord, newRow];
        this.isSpinner = false;
        console.log('this.escallationRecord ' + JSON.stringify(this.escallationRecord));

    }

    onAddRow() {
        this.isSpinner = false;
        for (let element of this.escallationRecord) {
            if (!element.Start_Date__c) {
                this.showToastMessage('Please Enter Start Date  For Row ' + element.key, 'error', 'error');
                return false; // Stop further validation
            }

            if (!element.Months__c) {
                this.showToastMessage('Please Enter Months For Row ' + element.key, 'error', 'error');
                return false; // Stop further validation
            }
        }
        this.isSpinner = true;
        this.addRow();
    }


    addRow() {
        this.escallationRecord = this.escallationRecord.map((row, index) => {


            return {
                ...row,
                disableAddRow: false,
                disableRemoveRow: true,
            };


        });

        let lastRow = parseInt(this.escallationRecord.length - 1);
        const EndDate = new Date(this.escallationRecord[lastRow].End_Date__c);
        //const propertyType = this.escallationRecord[lastRow].Property_Type__c;

        //alert(EndDate);
        const start_date = new Date(EndDate); // Create a copy of EndDate to avoid modifying the original
        start_date.setDate(start_date.getDate() + 1); // + 1 Add 1 day to the EndDate
      //  alert( new Date(start_date));
        const formattedStartdate = new Date(start_date).toISOString().split('T')[0];

        const newRow = {
            key: this.escallationRecord.length + 1,
            Start_Date__c: formattedStartdate,
            Months__c: 0,
            End_Date__c: null,
            ConfigurationOptions: this.configurationOptions,
            //Property_Type__c:propertyType,
            Configuration__c: [],
            Escalation__c: 0,
            Term_Sheet__c: this.recordId,
            disableStartDate: true,
            disableAddRow: false,
            disableRemoveRow: false,

        }

        this.escallationRecord.push(newRow);
        this.isSpinner = false;
        console.log('this.escallationRecord ' + JSON.stringify(this.escallationRecord));


    }
    removeRow(event) {
        // alert('remove');
       this.isSpinner =true;
        const rowIndex = parseInt(event.target.dataset.index, 10);
        // alert('rowIndex in remove ' + rowIndex);
        if (this.escallationRecord.length == 1) {

        } else {
            this.escallationRecord = this.escallationRecord.filter((_, index) => index !== rowIndex);
            this.escallationRecord = this.escallationRecord.map((row, index, array) => ({
                ...row,
                disableRemoveRow: index === array.length - 1 ? false : row.disableRemoveRow,
                key: index + 1,
            }));
        }
        this.isSpinner =false;
    }

    handleProperyTypeChange(event) {
        const value = event.target.value;

        this.selectedPropertyType = value;
        this.showRadioButton = false;

    }


    handleInputChange(event) {
        let fieldName = event.target.name;
        let value = event.target.value;
        let index = event.target.dataset.index;

        console.log('Field Name ' + fieldName + ' Value ' + value + ' index' + index);
        this.isSpinner = true;
        this.addValuesToEscalationRecord(fieldName, value, index);

        console.log('Escallation Record ' + JSON.stringify(this.escallationRecord));


    }

    addValuesToEscalationRecord(fieldName, value, index) {
        this.escallationRecord = this.escallationRecord.map((item, idx, array) => {
            if (index == idx && fieldName === 'Months__c' && item.Start_Date__c && value) {
                // Calculate End Date for the current row
                /* const start_date = new Date(item.Start_Date__c);
                 const end_date = new Date(start_date.setMonth(start_date.getMonth() + parseInt(value)));*/
                const start_date = new Date(item.Start_Date__c);
                const end_date = new Date(start_date); // Create a separate instance
                end_date.setMonth(end_date.getMonth() + parseInt(value)); // Add the months
                end_date.setDate(end_date.getDate() - 1); // Adjust to the last day of the previous month
                item.Months__c = value;
                item.End_Date__c = end_date.toISOString().split('T')[0];

                // Cascade updates to subsequent rows
                let updatedEndDate = new Date(item.End_Date__c);
                for (let i = idx + 1; i < array.length; i++) {
                    const nextStartDate = new Date(updatedEndDate);
                    nextStartDate.setDate(nextStartDate.getDate() + 1); // Next row's Start Date
                    array[i].Start_Date__c = nextStartDate.toISOString().split('T')[0];

                    const nextEndDate = new Date(nextStartDate);
                    nextEndDate.setMonth(nextEndDate.getMonth() + parseInt(array[i].Months__c || 0));
                    array[i].End_Date__c = nextEndDate.toISOString().split('T')[0];

                    updatedEndDate = nextEndDate; // Update reference for subsequent rows
                }
            } else if (index == idx && fieldName !== 'Months__c' && value) {
                item[fieldName] = value;
            } else if (fieldName === 'Months__c' && index == idx && !item.Start_Date__c && value) {
                this.showToastMessage(
                    'Please Enter Start Date for Line: ' + (parseInt(index) + 1),
                    'error',
                    'error'
                );
            }
            return item;
        });

        this.isSpinner =false;

        console.log('Updated Escallation Record:', JSON.stringify(this.escallationRecord));
    }


    validData() {
        for (let element of this.escallationRecord) {
            if (!element.Start_Date__c) {
                this.showToastMessage('Please Enter Start Date For Row ' + element.key, 'error', 'error');
                return false; // Stop further validation
            }

            if (!element.Months__c) {
                this.showToastMessage('Please Enter Months For Row ' + element.key, 'error', 'error');
                return false; // Stop further validation
            }
            /* if (!element.Property_Type__c) {
                 this.showToastMessage('Please Select Property Type For Row '+element.key, 'error', 'error');
                 return false; // Stop further validation
             }*/


            if (!element.Configuration__c || element.Configuration__c.length === 0) {
                this.showToastMessage('Please Select at least one Configuration for row ' + element.key, 'error', 'error');
                return false; // Stop further validation
            }

            //alert(typeof(element.Escalation__c));

            if ((element.Escalation__c === null || element.Escalation__c === undefined || element.Escalation__c === '' || isNaN(element.Escalation__c))) {
                this.showToastMessage('Please Enter %Escalation For Row ' + element.key, 'error', 'error');
                return false; // Stop further validation
            }
        }

        // Validate Escalation to be created are within the Term Sheet Timeline
        // TODO : Dates are not properly getting added based on actual month (but on actual days)
        //        review it ones

        const escalationStartDate = this.escallationRecord.find(record => record.key == 1)?.Start_Date__c;
        const escalationEndDate = this.escallationRecord.find(record => record.key == this.escallationRecord.length)?.End_Date__c;

        if(escalationStartDate != this.termSheet.Start_Date__c || escalationEndDate != this.termSheet.End_Date__c){
            alert('Please maken sure that, Escalations Dates must align with Terms Sheet\'s Start & End Date ');
            return false;
        }
        

        // If all records are valid
        return true;
    }

    handleSave() {
        if (this.validData()) {
            this.escallationRecord = this.escallationRecord.map(row => {
                // Prevent duplicate joining by checking if it already contains ";"
                if (!row.Configuration__c.includes(';')) {
                    return {
                        ...row,
                        Configuration__c: row.Configuration__c.join('; ') + ';'
                    };
                }
                return row;
            });
            
            console.log('escallationRecord : ' + JSON.stringify(this.escallationRecord));
            console.log('termsheet : ' + JSON.stringify(this.termSheet));
            
            this.isSpinner = true;
            saveEscallations({ escalltionList: this.escallationRecord, tremSheetId: this.recordId, propertyType: this.selectedPropertyType })
                .then(result => {
                    if (result == 'success') {
                        this.showToastMessage('Success', 'Records saved successfully!', 'success');
                        if (result) {
                            // Navigate to the record page
                            this[NavigationMixin.Navigate]({
                                type: 'standard__objectPage',
                                attributes: {
                                    objectApiName: 'Account', 
                                    actionName: 'list'        
                                }
                            });
                        }
                        this.isSpinner = false;

                    } else {
                        this.showToastMessage('Error While Creating Escalations !', result, 'error');
                        console.log('error0 ' + JSON.stringify(result));
                        this.isSpinner = false;
                    }


                }).catch(error => {
                    console.error('error0 ' + JSON.stringify(error));
                    this.showToastMessage('Please Contact System Admin', error, 'error');
                    this.isSpinner = false;
                });
        }
    }

    showToastMessage(title, message, variant) {

        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        })
        this.dispatchEvent(evt);

    }

}