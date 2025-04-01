import { LightningElement, track,wire,api} from 'lwc';
import checkGenerateWelcomeCallChecklist from '@salesforce/apex/Ex_BookingVerificationController.checkCreateBookingVerificationCheckList';
import changeGenarateCheckBoxValue from '@salesforce/apex/Ex_BookingVerificationController.changeGenarateCheckBoxValue';
import getWelcomCallDetails from '@salesforce/apex/Ex_BookingVerificationController.getBookingVerificationChecklistDetails';
import getBookings from '@salesforce/apex/Ex_BookingVerificationController.getBookings'; 
import updateRecords from '@salesforce/apex/Ex_BookingVerificationController.updateRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Ex_BookingVerificationComponent extends LightningElement {

    @api recordId;
    @api options;
    @api showButton = false;
    @track wccList;
    @track acceptAll = false;
    @track selectedval;
    @track selectedValues;
    @track rejectAll = false;

    @api isLoading = false;
    @track isSpinner = false;
    @track error;

    categoryData = [];
    @track data = [];

    @track projectName;
    @api showDetails = false;
    @track customerName;
    @track bookingDate;
    @track remark;

    get options() {
        return [
            { label: 'Accepted', value: 'Accepted' },
            { label: 'Rejected', value: 'Rejected' },
        ];
    }

    @wire(getBookings, { recordId: '$recordId' })
    getBkData({ data, error }){
        if (data) {
            this.data = data;
             console.log('this.data is::' + JSON.stringify(this.data));
             if(this.data.length > 0){
                this.projectName = this.data[0].Project__r.Name;
                
                this.customerName = ( this.data[0].Booking_Type__c != null && this.data[0].Booking_Type__c === 'Opportunity Based' && this.data[0].Opportunity__c != null && this.data[0].Opportunity__c != undefined) ? this.data[0].Opportunity__r.Name
                                   :(this.data[0].Booking_Type__c != null && this.data[0].Booking_Type__c === 'Tenant Based' && this.data[0].Tenant_Account__c != null && this.data[0].Tenant_Account__c != undefined) ? this.data[0].Tenant_Account__r.Name : '';
                this.bookingDate = (this.data[0].Booking_Date__c != null && this.data[0].Booking_Date__c != undefined) ? this.data[0].Booking_Date__c : '';

                console.log('this.projectName is::' + JSON.stringify(this.projectName));
                console.log('this.customerName is::' + JSON.stringify(this.customerName));
                console.log('this.bookingDate is::' + JSON.stringify(this.bookingDate));
            }else if (error) {
                this.error = error;
            }
        }
    }

    @wire(checkGenerateWelcomeCallChecklist, { recordId: '$recordId' }) 
    fetchData({ data, error }) {
        if (data) {
            this.data = data;
             console.log('this.data is::' + JSON.stringify(this.data));
        
            console.log('needToShow is::' + JSON.stringify(this.data));
            let needToShow = false;
            for (let i = 0; i < this.data.length; i++) {
                if (this.data[i].Id) {
                    needToShow = true;
                    break;
                }
            }
            if (needToShow) {
                this.showButton = true;
            } else {

                this.showButton = false;
                this.showDetails = true;
                this.getWelcomeCallChecklist();
            }
        } else if (error) {
            this.error = error;
        }
    }

    

    generateWelcomeCall(event){
        this.isLoading = true;
        this.showButton = false;
        changeGenarateCheckBoxValue({ recordId: this.recordId })
            .then(result => {
                console.log('result is::' + JSON.stringify(result));
                this.showDetails = true;
                if (this.showDetails === true) {
                    this.getWelcomeCallChecklist();

                }
            })
            .catch(error => {
                console.error('error is::' + JSON.stringify(this.error));
            });
    }

    getWelcomeCallChecklist() {

        getWelcomCallDetails({ bId: this.recordId })
            .then(result => {
                this.wccList = result;
                this.isLoading = false;
                
                this.categoryData = this.wccList;
                console.log('this.categoryData is::' + JSON.stringify(this.categoryData));;
            })
            .catch(error => {
                this.error = error;
                console.log('this.error is::' + JSON.stringify(this.error));
            });
    }

    renderedCallback() {
        if (this.isLoaded)
            return;
        const STYLE = document.createElement("style");
        STYLE.innerText = `.uiModal--medium .modal-container{
            width: 100% !important;
            max-width: 95%;
            min-width: 480px;
            max-height:100%;
            min-height:480px;
        };`
        this.template.querySelector('lightning-card').appendChild(STYLE);
        this.isLoaded = true;
    }

    handleOptions(event) {

        this.selectedValues = event.detail.value;
        console.log('selectedValues: ' + this.selectedValues);


        const key = parseInt(event.target.dataset.key);
        console.log(key);

        if (this.selectedValues == 'Accepted') {
            this.categoryData = this.categoryData.map((item, index) => {
                if (index === key) {
                    return { ...item, 'Decision__c': this.selectedValues,'Accepted__c': true};
                }
                return item;
            });
        }else{
            this.categoryData = this.categoryData.map((item, index) => {
                if (index === key) {
                    return { ...item, 'Decision__c': 'Rejected','Accepted__c': false};
                }
                return item;
            });
        }

       
        console.log('this.finalList is::' + JSON.stringify(this.categoryData));
    }

 
    handleAllAcceptChange(event) {
        this.acceptAll = event.target.checked;
        console.log('acceptAll: ' + this.acceptAll);
        if (this.acceptAll) {
            this.rejectAll = false;
            this.selectedval = this.options[0].value;
        } else {
            this.selectedval = '';
        }

        this.categoryData = this.categoryData.map((item, index) => {
           
                return { ...item, 'Decision__c': this.selectedval,'Accepted__c': (this.selectedval !== undefined && this.selectedval === 'Accepted') ? true : false};
            
        });

        console.log('this.finalList Accept is::' + JSON.stringify(this.categoryData));
    }

    handleAllRejectChange(event) {
        this.rejectAll = event.target.checked;
        console.log('acceptAll: ' + this.rejectAll);

        if (this.rejectAll) {
            this.acceptAll = false;
            this.selectedval = this.options[1].value;
        } else {
            this.selectedval = '';
        }

        this.categoryData = this.categoryData.map((item, index) => {
            
                return { ...item, 'Decision__c': this.selectedval,'Accepted__c': false};
            
        });
        console.log('this.finalList reject is::' + JSON.stringify(this.categoryData));
    }

    handleRemarks(event) {
        this.remark = event.target.value;
    }

    handleSubmit() {
        if (!this.acceptAll && !this.rejectAll && this.categoryData.length === 0) {
            this.showToast('Error', 'Please select at least one option (Accept or Reject).', 'error');
            return;
        }
        if (!this.remark || this.remark.trim() === '') {
            this.showToast('Error', 'Please Enter Remarks.', 'error');
            return;
        }
        let updatedRecords = [];

        if (this.acceptAll) {
            this.wccList.forEach(item => {
                if (!item.Accepted__c) {
                    console.log('point 11');
                    updatedRecords.push({
                        Id: item.Id,
                        Decision__c: 'Accepted',
                        Accepted__c: true
                    });
                }
            });
        } else if (this.rejectAll) {
            this.wccList.forEach(item => {
                if (!item.Accepted__c) {
                    console.log('point 12');
                    updatedRecords.push({
                        Id: item.Id,
                        Decision__c: 'Rejected',
                        Accepted__c: false
                    });
                }
            });
        }
        if (updatedRecords.length > 0 || this.categoryData.length > 0) {
            console.log('updatedRecords are::' + JSON.stringify(updatedRecords));
            this.isSpinner = true;
            updateRecords({ records: updatedRecords, ConfirmedVerificationList: this.categoryData, bookId: this.recordId, VerificationRemarks: this.remark})
                .then(result => {
                    this.showSuccess();
                    window.location.href = '/' + result;
                })
                .catch(error => {
                    this.error = error;
                    this.isSpinner = false;
                    console.error('Error:', JSON.stringify(this.error));
                    const evt = new ShowToastEvent({
                        title: "Error",
                        message: error.body && error.body.message ? error.body.message : 'An unexpected error occurred.',
                        variant: "error"
                    });
                    this.dispatchEvent(evt);
                });

        }
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }
    showSuccess() {
        const evt = new ShowToastEvent({
            title: "Success",
            message: "Booking verification completed successfully!",
            variant: "success"
        });
        this.dispatchEvent(evt);
    }

    

}