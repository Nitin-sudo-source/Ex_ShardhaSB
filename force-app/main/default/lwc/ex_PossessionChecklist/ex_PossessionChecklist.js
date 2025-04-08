import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMasterPossession from '@salesforce/apex/Ex_PossessionchecklistController.getMasterPossession';
import getBookingDetails from '@salesforce/apex/Ex_PossessionchecklistController.getBookingDetails';
import savePossessionCheckList from '@salesforce/apex/Ex_PossessionchecklistController.savePossessionCheckList';
import getPossessionChecklist from '@salesforce/apex/Ex_PossessionchecklistController.getPossessionChecklist';
import updatePossessionChecklistStatusFromCRMHead from '@salesforce/apex/Ex_PossessionchecklistController.updatePossessionChecklistStatusFromCRMHead';
import checkIfGuestUser from '@salesforce/apex/Ex_PossessionchecklistController.checkIfGuestUser';

export default class Ex_PossessionChecklist extends LightningElement {
    @api recordId;
    @track booking = [];
    @track possessionChecklistMap = [];
    @track saveArray = [];
    @track possessionChecklistArray = [];
    @track isCRMManager = false;
    @track isAccManager = false;
    @track isCRMHead = false;
    @track isGuestUser = false;
    @track alreadyCheckList = false;
    @track errorMsg = '';
    @track showData = false;
    @track accountData = [];
    @track accScuccess = false;
    @track accScuccessMessage = '';
    @track isSpinner = false;
    @track checklistData = [];

    get processedData() {
        return this.accountData.map((item, index) => ({
            ...item,
            serialNumber: index + 1
        }));
    }
    get recOption() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }
    get ItemStatus() {
        return [
            { label: 'Completed', value: 'Completed' },
            { label: 'Pending', value: 'Pending' },
            { label: 'NA', value: 'NA' }
        ];
    }

    async connectedCallback() {
        const urlSearchParams = new URLSearchParams(window.location.search);

        this.recordId = urlSearchParams.get('recordId');
        if (this.recordId) {
            console.log('Found recordId:', this.recordId);
        } else {
            console.log('No recordId found in the URL.');
        }

        this.isAccManager = urlSearchParams.get('isAccManager') === 'true';
        console.log('Is Acc Manager:', this.isAccManager);

        this.isCRMHead = urlSearchParams.get('isCRMHead') === 'true';
        console.log('Is isCRMHead:', this.isCRMHead);

        this.isCustomer = urlSearchParams.get('isCustomer') === 'true';
        console.log('Is isCustomer:', this.isCustomer);

        if (this.isCRMHead) {
            this.isCRMManager = true
            this.isAccManager = true;
        }
        // Fetch additional data if necessary
        await this.fetchData();
    }

    // async handleCheckGuestUser() {
    //     try {
    //         const result = await checkIfGuestUser({
    //             siteURL: window.location.href,
    //             bookingId: this.recordId
    //         });
    //         this.isGuestUser = result;
    //         console.log('isGuestUser:', this.isGuestUser);
    //     } catch (error) {
    //         console.error('Error:', error);
    //         this.showErrorMessage('error', 'Some internal error occurred!');
    //     }
    // }


    @wire(getBookingDetails, { bkId: '$recordId' })
    booking({ error, data }) {
        if (data) {
            this.registration = data.booking.Registration_Status__c;
            console.log(' this.registration : ', JSON.stringify(this.registration));
            if (this.registration != undefined && this.registration == 'Completed') {
                this.booking = data.booking;
                console.log(' this.booking : ', JSON.stringify(this.booking));

                this.isCRMManager = data.isCRMManager;
                if (this.isCRMHead) {
                    this.isAccManager = false;
                }
                if (this.isCRMManager && this.booking.CRM_Possession_Checklist__c) {
                    this.alreadyCheckList = true;
                    this.errorMsg = 'CRM Checklist Already Done.';
                }
                else if (!this.isCRMHead && this.isAccManager && this.booking.Account_Possession_Checklist__c) {
                    this.alreadyCheckList = true;
                    this.errorMsg = 'FM Checklist Already Done.';
                }
                else if (this.isCRMHead && this.booking.Possession_Approved_By_CRM_Head__c) {
                    this.alreadyCheckList = true;
                    this.errorMsg = 'CRM Head Approval Already Done.';
                }
                else if (this.isCustomer && this.booking.Customer_Possession_Checklist__c) {
                    this.alreadyCheckList = true;
                    this.errorMsg = 'Customer Checklist Already Done.';
                }

                if (!this.isCRMManager && !this.isAccManager && !this.isCRMHead && !this.isCustomer) {
                    this.errorMsg = 'You have no access for possession checklist.';
                    this.showData = false;
                } else {
                    this.showData = true;
                }
                console.log('this.isCRMManager. : ', JSON.stringify(this.isCRMManager));
                console.log('this.isAccManager. : ', JSON.stringify(this.isAccManager));
                console.log('this.isCRMHead. : ', JSON.stringify(this.isCRMHead));
            } else {
                this.errorMsg = 'Registration not done yet.';
                this.showData = false;
            }

            this.fetchData();
        } else if (error) {
            console.error('Error fetching booking details:', error);
            this.booking = undefined;
            this.isCRMManager = false;
            this.isAccManager = false;
        }
    }

    async fetchData() {
        try {
            const [pcDetails, data] = await Promise.all([
                getPossessionChecklist({ bkId: this.recordId }),
                getMasterPossession({
                    bkId: this.recordId,
                    isCRMManager: this.isCRMManager,
                    isAccManager: this.isAccManager,
                    isCustomer: this.isCustomer
                })
            ]);

            if (data) {
                let map = data.reduce((acc, item, index) => {
                    if (!acc[item.Section__c]) {
                        acc[item.Section__c] = [];
                    }

                    let receivedValue = '';
                    let remarksValue = '';
                    let statusValue = '';
                    let fmStatusValue = '';
                    let customerStatusValue = '';

                    if (pcDetails) {
                        this.checklistData = pcDetails;
                        console.log('this.checklistData:', JSON.stringify(this.checklistData));
                        pcDetails.forEach(pc => {
                            if (pc.Section__c === item.Section__c && pc.Particulars__c === item.Particulars__c) {
                                receivedValue = pc.Received__c;
                                remarksValue = pc.Remarks__c;
                                statusValue = pc.Status__c;
                                fmStatusValue = pc.FM_Status__c; // Extract FM_Status__c
                                customerStatusValue = pc.Customer_Status__c; // Extract Customer_Status__c
                                console.log('remarksValue:', remarksValue);
                                console.log('statusValue:', statusValue);
                                console.log('fmStatusValue:', fmStatusValue);
                            }
                        });
                    }

                    acc[item.Section__c].push({
                        ...item,
                        Received__c: receivedValue,
                        Status__c: statusValue || '',
                        Remarks__c: remarksValue || '',
                        FM_Status__c: fmStatusValue || '',
                        Customer_Status__c: customerStatusValue || '',
                        Index__c: index,
                        isHideRemark: item.Section__c === 'Documents handed over to customer',
                        isAccManager: item.Section__c === 'Documents received from customer'
                    });

                    return acc;
                }, {});

                this.possessionChecklistArray = Object.keys(map).map(section => ({
                    sectionName: section,
                    items: map[section],
                    isHideRemark: map[section][0].isHideRemark,
                    isAccManager: map[section][0].isAccManager
                }));

                console.log('possessionChecklistArray:', JSON.stringify(this.possessionChecklistArray));

                this.error = undefined;
            } else {
                this.possessionChecklistArray = [];
                console.error('No data returned from Apex method.');
            }

            if (pcDetails) {
                this.accountData = this.accountData.map(item => {
                    pcDetails.forEach(pc => {
                        if (pc.Section__c === item.Section__c && pc.Particulars__c === item.Particulars__c) {
                            item.Accounts_Clearance__c = pc.Accounts_Clearance__c;
                        }
                    });
                    return item;
                });
            }

            console.log('this.accountData:', JSON.stringify(this.accountData));
        } catch (error) {
            this.error = error;
            this.possessionChecklistArray = [];
            console.error('Error fetching data:', error);
        }
    }


    get showSubmitButton() {
        return this.possessionChecklistArray && this.possessionChecklistArray.length > 0;
    }


    handleAcceptAllCRMChecklist(event) {
        const sectionIndex = event.target.dataset.index;
        const acceptAllChecked = event.target.checked;

        // Update all items in the selected section
        this.possessionChecklistArray = this.possessionChecklistArray.map((section, index) => {
            if (index == sectionIndex) {
                section.items = section.items.map(item => ({
                    ...item,
                    Status__c: acceptAllChecked ? 'Completed' : 'NA',
                }));
            }
            return section;
        });

    }

    handleAcceptAllAccounthecklist(event) {
        const sectionIndex = event.target.dataset.index;
        const acceptAllChecked = event.target.checked;

        // Update all items in the selected section
        this.possessionChecklistArray = this.possessionChecklistArray.map((section, index) => {
            if (index == sectionIndex) {
                section.items = section.items.map(item => ({
                    ...item,
                    FM_Status__c: acceptAllChecked ? 'Completed' : 'NA',
                }));
            }
            return section;
        });
        console.log('handleAcceptAllChange: ', JSON.stringify(this.possessionChecklistArray));


    }
    handleAcceptAllCustomerChecklist(event) {
        const sectionIndex = event.target.dataset.index;
        const acceptAllChecked = event.target.checked;

        // Update all items in the selected section
        this.possessionChecklistArray = this.possessionChecklistArray.map((section, index) => {
            if (index == sectionIndex) {
                section.items = section.items.map(item => ({
                    ...item,
                    Customer_Status__c: acceptAllChecked ? 'Completed' : 'NA',
                }));
            }
            return section;
        });

    }



    handleChange(event) {
        let index = event.target.dataset.index;
        let value = event.target.value;
        let name = event.target.name;
        console.log('index : ', index);
        console.log('value : ', value);
        console.log('name : ', name);

        this.possessionChecklistArray.forEach(section => {
            section.items = section.items.map(item => {
                if (item.Index__c == index) {
                    if (name === 'received') {
                        return { ...item, Received__c: value };
                    }
                    if (name === 'Status__c') {
                        return { ...item, Status__c: value };
                    }
                    if (name === 'FM_Status__c') {
                        return { ...item, FM_Status__c: value };
                    }
                    if (name === 'Customer_Status__c') {
                        return { ...item, Customer_Status__c: value };
                    }
                    else if (name === 'remarks') {
                        return { ...item, Remarks__c: value };
                    }

                }
                return item;
            });
        });
    }

    handleSubmit() {
        let checklistIdentifier = '';
        let recordsToSave = [];
        this.isSpinner = true;

        // Helper function for validation
        const validateChecklist = (key) => {
            return this.possessionChecklistArray.every(section => {
                return section.items.every(item => item[key] !== undefined && item[key] !== '');
            });
        };

        // Validation and Checklist Identifier Assignment
        if (this.isAccManager) {
            checklistIdentifier = 'Account Manager';
            if (!validateChecklist('FM_Status__c')) {
                this.showErrorMessage('error', 'Please select FM Status options for all items before saving.');
                this.isSpinner = false;
                return;
            }
        } else if (this.isCRMManager) {
            checklistIdentifier = 'CRM Manager';
            if (!validateChecklist('Status__c')) {
                this.showErrorMessage('error', 'Please select Status options for all items before saving.');
                this.isSpinner = false;
                return;
            }
        } else if (this.isCustomer) {
            checklistIdentifier = 'Customer';
            if (!validateChecklist('Customer_Status__c')) {
                this.showErrorMessage('error', 'Please select Customer Status options for all items before saving.');
                this.isSpinner = false;
                return;
            }
        }

        // Collect records to save
        this.possessionChecklistArray.forEach(section => {
            section.items.forEach(item => {
                recordsToSave.push({
                    Particulars__c: item.Particulars__c,
                    Received__c: item.Received__c,
                    Status__c: item.Status__c,
                    Customer_Status__c: item.Customer_Status__c,
                    FM_Status__c: item.FM_Status__c,
                    Booking__c: this.recordId,
                    Remarks__c: item.Remarks__c,
                    Section__c: item.Section__c,
                    Checklist_Identifier__c: checklistIdentifier
                });
            });
        });

        // Save Checklist Records
        savePossessionCheckList({ mpList: recordsToSave, bkId: this.recordId, isAccManager: this.isAccManager, isCRMManager: this.isCRMManager, isCustomer: this.isCustomer })
            .then(() => {
                let successMessage = 'Records upserted successfully.';
                if (this.isAccManager || this.isCustomer) {
                    successMessage = 'Possession Checklist updated successfully.';
                    this.accScuccess = true;
                    this.accScuccessMessage = 'Your possession checklist has been updated successfully.';
                }
                this.showSuccessMessage('success', successMessage);

                if (this.isCRMManager) {
                    location.replace('/' + this.recordId);
                }
                this.isSpinner = false;
            })
            .catch(error => {
                console.error('Error while saving records:', error);
                this.showErrorMessage('error', 'Error creating records: ' + error.body.message);
                this.isSpinner = false;
            });
    }

    handleCRMHeadApproval(event) {

        const _approvalStatus = event.target.dataset.approvalStatus;

        updatePossessionChecklistStatusFromCRMHead({ bookingId: this.recordId, approvalStatus: _approvalStatus })
            .then(data => {
                if (data == true) {
                    if (_approvalStatus == "Approved") {
                        this.showSuccessMessage('success', 'Approved Possession Checklist !');
                        this.accScuccess = true;
                        this.accScuccessMessage = 'Your Approval Request Submitted Sucessfully.';
                    }
                    else if (_approvalStatus == "Rejected") {
                        this.showSuccessMessage('error', 'Rejected Possession Checklist !');
                        this.accScuccess = true;
                        this.accScuccessMessage = 'Your Approval Request Submitted Sucessfully.';
                    }
                }
                else {
                    this.showErrorMessage('error', 'Some internal error occurred !');

                }
            })
            .catch(error => {
                this.showErrorMessage('error', 'Some internal error occurred !');
            })
    }


    showErrorMessage(type, message) {
        this.isSpinner = false;
        this.template.querySelector('c-custom-toast').showToast(type, message, 'utility:error', 10000);
    }
    showSuccessMessage(type, message) {
        this.isSpinner = false;
        this.template.querySelector('c-custom-toast').showToast(type, message, 'utility:success', 10000);
    }
}