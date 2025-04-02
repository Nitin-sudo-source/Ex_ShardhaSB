/**
 * @description       : 
 * @author            : nitinSFDC@exceller.SFDoc
 * @group             : 
 * @last modified on  : 01-04-2025
 * @last modified by  : nitinSFDC@exceller.SFDoc
**/
import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import sendEmailOnClick from '@salesforce/apex/Ex_WelcomeEmailSend.sendEmailOnClick';

export default class Ex_Welcome_Call_Email extends NavigationMixin(LightningElement) {
    // Modal Configuration
    @api isVisible;
    @api modalTitle = 'Welcome Call Email ';
    @api headerIcon = 'action:email';
    @api yesButtonLabel = 'Yes';
    @api noButtonLabel = 'No';
    @track getResPonse = {};
    @track disabledYes = false;

    // Toast Configuration
    @api showToast = false;
    @api toastMessage = '';
    @api toastVariant = 'success'; // 'success', 'warning', 'error'
    toastTimeout;
    @api recordId;
    pdfData;

    // Public method to open modal
    @api
    open() {
        this.isVisible = true;
    }

    // Public method to close modal
    @api
    close() {
        this.isVisible = false;
    }

    // Public method to show toast
    @api
    showToastMessage(message, variant = 'success') {
        this.toastMessage = message;
        this.toastVariant = variant;
        this.showToast = true;

        // Auto-hide after duration
        // clearTimeout(this.toastTimeout);
        // this.toastTimeout = setTimeout(() => {
        //     this.hideToast();
        // }, duration);
    }

    hideToast() {
        this.showToast = false;
    }

    handleClose() {
        //this.close();
        this.dispatchEvent(new CustomEvent('close'));
        this.navigateToViewBookingPage();
    }

    handleYes() {
        this.disabledYes = true;
       
        this.dispatchEvent(new CustomEvent('yes'));
        // alert('RecordId: ' + this.recordId);
        sendEmailOnClick({ recordId: this.recordId })
            .then((result) => {
                console.log('result : ' + JSON.stringify(result));
                this.getResPonse = result;
                console.log('OUTPUT : ' + JSON.stringify(this.getResPonse));
                alert(this.getResPonse.bookingRecord.Name + ' Successfully Send Email To  ' +this.getResPonse.recipientEmail);
                

                // setInterval(() => {
                    location.replace('/' + this.getResPonse.bookingRecord.Id);
                // }, 3000);
            })
            
            .catch(error => {
                this.showToastMessage(error, 'error');
                this.getResPonse = '';
            });
            
           

    }



    handleNo() {
        this.handleClose();
        this.dispatchEvent(new CustomEvent('no'));
        //this.showToastMessage('Action cancelled', 'warning');
        this.navigateToViewBookingPage();
    }

    get toastIcon() {
        switch (this.toastVariant) {
            case 'success': return 'utility:success';
            case 'warning': return 'utility:warning';
            case 'error': return 'utility:error';
            default: return 'utility:success';
        }
    }

    // Handle escape key press
    handleKeyDown(event) {
        if (event.key === 'Escape') {
            this.handleClose();
        }
    }

    connectedCallback() {
        const urlSearchParams = new URLSearchParams(window.location.search);
        this.recordId = urlSearchParams.get("recordId");
        console.log("Watch: varName ->" + this.recordId); /*eslint-disable-line*/
        console.log("Watch: recordId ->" + this.recordId); /*eslint-disable-line*/

        window.addEventListener('keydown', this.handleKeyDown.bind(this));
    }

    disconnectedCallback() {
        window.removeEventListener('keydown', this.handleKeyDown.bind(this));
        clearTimeout(this.toastTimeout);
    }


    navigateToViewBookingPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Booking__c',
                actionName: 'view'
            },
        });
    }










}