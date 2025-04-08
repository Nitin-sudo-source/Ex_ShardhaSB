/**
 * @description       : 
 * @author            : nitinSFDC@exceller.SFDoc
 * @group             : 
 * @last modified on  : 08-04-2025
 * @last modified by  : nitinSFDC@exceller.SFDoc
**/
import { LightningElement, api, wire, track } from 'lwc';
import getProject from '@salesforce/apex/Ex_BulkDemandApprovalDashboard.getProject';
import getTower from '@salesforce/apex/Ex_BulkDemandApprovalDashboard.getTower';
import getBookings from '@salesforce/apex/Ex_BulkDemandApprovalDashboard.getBookings';
import getPMDetails from '@salesforce/apex/Ex_BulkDemandApprovalDashboard.getPMDetails';
import getDemandDetails from '@salesforce/apex/Ex_BulkDemandApprovalDashboard.getDemandDetails';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class Ex_BulkDemandApprovalDownload extends NavigationMixin(LightningElement) {

    @track selectedFinalist = [];
    @track projectId = '';
    @track towerId = '';
    @track documentType = '';
    @track regData = [];
    @track showTable = false;
    @track isSpinner = false;
    @track selectedList = [];
    @track currentPage = 1;
    @track pageSize = 10;
    @track index = 0;
    @track checkboxesState = {};
    @track regId = '';
    @track mainList = [];
    @track selectAllcheckBox = false;
    @track finalurl = '';
    @track url = [];
    @track isError = false;
    @track errorMsg = '';
    @track filteredRecords = []; // Data after applying filters
    @track activeStatusFilter = ''; //
    @track sortDirection = 'ASC';
    @track sortedBy = '';
    @track pmDetail = [];

    isListening = false;

    @track pickListOrdered = [];
    @track searchResults;
    @track selectedSearchResult = {};
    @track pmDetailsOptions;

    @track showModal = false;
    @track modalRecords = [];
    @track modalTitle = '';
    autoCloseTimeout;
    @track getCount = 0;
    pmId = '';

   

   

    
    @wire(getProject) getProjectData;
    @wire(getTower, { ProjectId: '$projectId' }) getTowerData;

    renderedCallback() {
        if (this.isListening) return;

        window.addEventListener("click", (event) => {
            this.hideDropdown(event);
        });
        this.isListening = true;
    }

    get selectedValue() {
        return this.selectedSearchResult?.label ?? null;
    }

    get projectOptions() {
        return this.getProjectData.data ? this.getProjectData.data.map(p => ({ label: p.Name, value: p.Id })) : [];
    }

    get pm() {
        const pmOptions = this.pmDetail 
            ? this.pmDetail.map(item => ({
                label: item.paymentmilestone.Milestone_Name__c,
                value: item.paymentmilestone.Id
            })) 
            : [];
            return [{ label: 'All', value: 'all' }, ...pmOptions];

    }

    get towerOptions() {
        return this.getTowerData.data ? this.getTowerData.data.map(t => ({ label: t.Name, value: t.Id })) : [];
    }

    getSortIcon() {
        return this.sortDirection === 'ASC' ? 'utility:arrowup' : 'utility:arrowdown';
    }

    getSortVariant() {
        return this.sortDirection === 'ASC' ? 'success' : 'error';
    }

    //Pagination Logic Start

    get totalPages() {
        return Math.ceil(this.regData.length / this.pageSize);
    }
    get startRecord() {
        return (this.currentPage - 1) * this.pageSize;
    }
    get endRecord() {
        return Math.min(this.startRecord + this.pageSize, this.regData.length);
    }
    get currentPageData() {
        if (!this.regData || this.regData.length === 0) {
            return [];
        }

        let data = [...this.regData];

        // Apply Sorting
        if (this.sortedBy !== '') {
            data.sort((a, b) => {
                let fieldA = a[this.sortedBy] || '';
                let fieldB = b[this.sortedBy] || '';

                if (this.sortedBy === 'registrationDate') {
                    return this.sortDirection === 'ASC'
                        ? new Date(fieldA) - new Date(fieldB)
                        : new Date(fieldB) - new Date(fieldA);
                }

                return this.sortDirection === 'ASC'
                    ? fieldA > fieldB ? 1 : -1
                    : fieldA < fieldB ? 1 : -1;
            });

            const currentPageData = data.slice(this.startRecord, this.endRecord);
            currentPageData.forEach((item, index) => {
                item.serialNumber = this.startRecord + index + 1;
            });

            return currentPageData;
        } else {

            return this.regData.slice(this.startRecord, this.endRecord);
        }
    }

    get isPreviousDisabled() {
        return this.currentPage === 1;
    }
    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }

    get projectTitle() {
        return this.projectId ? 'Project Selected' : 'Please Select Project';
    }

    get towerTitle() {
        return this.towerId ? 'Tower Selected' : 'Please Select Tower';
    }

    get recordSelected() {
        // this.getCount = 0;
        let count = 0;

        for (let record of this.regData) {
            if (
                this.mainList.includes(String(record.demand.Id)) &&
                record.isSelected &&
                record.approvalStatus === 'Pending for approval'
            ) {
                count++;
            }
        }
        //this.getCount = count;
        return count;
    }

    get recordSelectedRejected() {
        //this.getCount = 0;
        let count = 0;

        for (let record of this.regData) {
            if (
                this.mainList.includes(String(record.demand.Id)) &&
                record.isSelected &&
                record.approvalStatus === 'Rejected'
            ) {
                count++;
            }
        }
        //this.getCount = count;
        return count;
    }

    get recordSelectedApproved() {
        // this.getCount = 0;
        let count = 0;

        for (let record of this.regData) {
            if (
                this.mainList.includes(String(record.demand.Id)) &&
                record.isSelected &&
                record.approvalStatus === 'Approved'
            ) {
                count++;
            }
        }
        //this.getCount = count;
        return count;
    }

   

    
    filteronview(filterstatus) {
        return this.regData
            .filter(record =>
                this.mainList.includes(String(record.demand.Id)) &&
                record.isSelected &&
                record.approvalStatus === filterstatus
            )
            .map(record => `• ${record.demand.Name}`);
    }


    handleBulkPending(event) {
        const dataName = event.target.dataset.name;
        const filterData = this.filteronview(dataName);

        this.showModalWithRecords(`Selected Records ${dataName}`, filterData, true);

        if (filterData.length === 0) {
            this.showModalWithRecords('No Selected Records', filterData, true);
        }

        this.showModal = true;
    }


    getBooking() {
        getBookings({ ProjectId: this.projectId, TowerId: this.towerId }).then((result) => {
            console.log('getBooking result: ' + JSON.stringify(result));
            // Transform booking data into picklist format
            this.pickListOrdered = result.map(item => ({
                label: item.booking.Name + ' - ' + item.booking.Unit__r.Name + ' - ' + item.booking.Primary_Applicant_Name__c,
                value: item.booking.Id,
                qid: item.booking.Quotation__c
            }));

            // Optional: sort alphabetically by label
            this.pickListOrdered.sort((a, b) => a.label.localeCompare(b.label));

        });
    }


    getPMDetail() {
        getPMDetails({ qId: this.selectedSearchResult.qid }).then((result) => {
            console.log('getPMDetail result: ' + JSON.stringify(result));
            this.pmDetail = result;
            this.pmDetailsOptions = result.map(item => ({
                label: item.paymentmilestone.Name,
                value: item.paymentmilestone.Id,
            }));
            });
            console.log(this.pmDetailsOptions);
    }


    fetchDocumentRecords() {

        console.log('label :' + this.selectedSearchResult.label);
        console.log('value: :' + this.selectedSearchResult.value);
        console.log('qid: :' + this.selectedSearchResult.qid);
        console.log('projectId: :' + this.projectId);
        console.log('towerId: :' + this.towerId);


        if (this.projectId === '' || this.projectId == '') {
            this.showToast('Warning', 'Please select Project', 'warning');
            return;
        } else if (this.towerId === '' || this.towerId == '') {
            this.showToast('Warning', 'Please select Tower', 'warning');
            return;
        }
        // else if (this.documentType == null || this.documentType === '' || this.documentType == '') {
        //     this.showToast('Warning', 'Please select Document Type', 'warning');
        //     return;
        // }
        else {
            this.showTable = false;
            this.isSpinner = true;
            getDemandDetails({ bId: this.selectedSearchResult.value, startDate: this.startDate, endDate: this.endDate, mType: this.pmId })
                .then((result) => {
                    console.log('fetch demands' + JSON.stringify(result));

                    if (result != null) {
                        this.regData = result.map((item, index) => ({
                            ...item,
                            // contentSizeKB: (item.contentSize / 1024).toFixed(2) + 'KB',
                            isSelected: false,
                            // isDownloaded: item.isDownloaded,
                            // "url": `/sfc/servlet.shepherd/document/download/${item.contentDocumentId}`,
                            "serialNumber": index + 1,
                            // previewUrl: `/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=${item.contentVersionId}`

                        }));
                        this.showTable = true;
                        this.isSpinner = false;
                        console.log('regData: ' + JSON.stringify(this.regData));
                        this.selectedList = this.regData;
                        this.selectAllcheckBox = false;
                        this.mainList = [];
                        // this.finalurl = '';
                        // this.url = [];
                        this.modalRecords = [];
                        //console.log('selectedList: ' + JSON.stringify(this.selectedList));

                    } else {
                        this.showToast('Warning', 'No Demands Found', 'warning');
                        this.showTable = false;
                        this.isSpinner = false;
                        this.selectAllcheckBox = false;
                        // this.finalurl = '';
                        this.mainList = [];
                        this.modalRecords = [];
                    }

                    if (this.regData.length === 0) {
                        this.showToast('Warning', 'No Demands Found', 'warning');
                        this.showTable = false;
                        this.isSpinner = false;
                        this.selectAllcheckBox = false;
                        // this.finalurl = '';
                        this.mainList = [];
                        this.modalRecords = [];
                    }


                })
                .catch((error) => {
                    console.error(error);
                    this.showToast('Warning', 'Something Went Wrong', 'warning');
                    this.showTable = false;
                    this.isSpinner = false;
                    this.selectAllcheckBox = false;
                    // this.finalurl = '';
                    this.mainList = [];
                    this.modalRecords = [];
                });
            this.showModalWithRecords('No Selected Record', this.modalRecords, false);
        }


    }






    hideDropdown(event) {
        const cmpName = this.template.host.tagName;
        const clickedElementSrcName = event.target.tagName;
        const isClickedOutside = cmpName !== clickedElementSrcName;
        if (this.searchResults && isClickedOutside) {
            this.clearSearchResults();
        }
    }

    search(event) {
        const input = event.detail.value.toLowerCase();
        const result = this.pickListOrdered.filter((pickListOption) =>
            pickListOption.label.toLowerCase().includes(input)
        );
        this.searchResults = result;
    }

    selectSearchResult(event) {
        const selectedValue = event.currentTarget.dataset.value;
        const qid = event.target.dataset.qid;
        this.selectedSearchResult = this.pickListOrdered.find(
            (pickListOption) => pickListOption.value === selectedValue
        );
        console.log('selectedSearchResult' + JSON.stringify(this.selectedSearchResult));
        this.getPMDetail();
        this.clearSearchResults();
    }

    clearSearchResults() {
        this.searchResults = null;
    }

    showPickListOptions() {
        if (!this.searchResults) {
            this.searchResults = this.pickListOrdered;
        }
    }



    // @track sortIcons = {
    //     bookingNo: { icon: 'utility:arrowdown', text: 'ASC', variant: 'success', size: 'small' },
    //     bookingStatus: { icon: 'utility:arrowdown', text: 'ASC', variant: 'success', size: 'small' },
    //     registrationDate: { icon: 'utility:arrowdown', text: 'ASC', variant: 'success', size: 'small' },
    //     UnitName: { icon: 'utility:arrowdown', text: 'ASC', variant: 'success', size: 'small' },
    //     fileType: { icon: 'utility:arrowdown', text: 'ASC', variant: 'success', size: 'small' }
    // };

    handleProjectChange(event) {
        this.projectId = event.target.value;
        alert(this.projectId);
    }

    handleTowerChange(event) {
        this.towerId = event.target.value;
        alert(this.towerId);
        this.getBooking();

    }

    handleMilestone(event){
        this.pmId = event.target.value;
        console.log(this.pmId);
        //this.getMilestone();
    
    }

    @track startDate = '';
    @track endDate = '';

    handleStartDate(event){
        this.startDate = event.target.value;
        console.log(this.startDate);

    }

    handleEndDate(event){
        this.endDate = event.target.value;
        console.log(this.endDate);
    }




    handleBulkApproved() {
        console.log('FinalMainList: ', JSON.stringify(this.mainList));

        let approvedList = [];
        let alreadyApprovedList = [];

        if (!this.mainList || this.mainList.length === 0) {
            this.showToast('Warning', 'Please select a record to approve', 'warning');
            return;
        }

        for (let i = 0; i < this.regData.length; i++) {
            const record = this.regData[i];
            const value = record.demand.Id;

            if (this.mainList.includes(value) && record.isSelected) {
                if (record.approvalStatus === 'Approved') {
                    alreadyApprovedList.push(`• ${record.demand.Name}`);

                } else {
                    approvedList.push(`• ${record.demand.Name}`);
                    record.approvalStatus = 'Approved';
                }
            }
        }

        // Show toast for newly approved records
        if (approvedList.length > 0) {
            //  const approvedMessage = approvedList.join('\n');
            this.showModalWithRecords('Approved Demands', approvedList, true);

            //this.showToast('Approved Demands', approvedList.join('\n'), 'success');
        }

        // Show toast for already approved records
        if (alreadyApprovedList.length > 0) {
            // const alreadyApprovedMessage = alreadyApprovedList.join('\n');
            //this.showToast('Already Approved', alreadyApprovedList.join('\n'), 'info');
            this.showModalWithRecords('Already Approved Demands', alreadyApprovedList, true);

        }
    }

    handleBulkRejected() {
        console.log('FinalMainList: ', JSON.stringify(this.mainList));

        if (!this.mainList || this.mainList.length === 0) {
            this.showToast('Warning', 'Please select a record to Reject', 'warning');
            return;
        }

        let rejectedList = [];
        let alreadyRejectedList = [];

        for (let i = 0; i < this.regData.length; i++) {
            const record = this.regData[i];
            const value = record.demand.Id;

            if (this.mainList.includes(value) && record.isSelected) {
                if (record.approvalStatus === 'Rejected') {
                    alreadyRejectedList.push(`• ${record.demand.Name}`);
                } else {
                    rejectedList.push(`• ${record.demand.Name}`);
                    record.approvalStatus = 'Rejected';
                }
            }
        }

        // Show toast for newly rejected records
        if (rejectedList.length > 0) {
            //const rejectedMessage = rejectedList.join('\n');
            this.showModalWithRecords('Rejected Demands', rejectedList, true);
        }

        // Show toast for already rejected records
        if (alreadyRejectedList.length > 0) {
            // const alreadyRejectedMessage = alreadyRejectedList.join('\n');
            this.showModalWithRecords('Already Rejected', alreadyRejectedList, true);
        }
    }


    handleSort(event) {
        const fieldName = event.target.dataset.field;
        const isSameField = this.sortedBy === fieldName;
        this.sortDirection = isSameField && this.sortDirection === 'ASC' ? 'DESC' : 'ASC';
        this.sortedBy = fieldName;
        this.sortIcons = {
            ...this.sortIcons,
            [fieldName]: {
                icon: this.sortDirection === 'ASC' ? 'utility:arrowup' : 'utility:arrowdown',
                text: this.sortDirection === 'ASC' ? 'ASC' : 'DESC',
                variant: this.getSortVariant(),
                size: 'small'
            }
        };
    }


    openBooking(event) {
        var value = event.target.dataset.id;
        //console.log(value);
        window.open(`/${value}`, '_blank');
    }



    handleAllSelected(event) {
        const checkboxes = this.template.querySelectorAll('[data-id^="checkbox-button"]');
        //console.log('checkboxes: ' + JSON.stringify(checkboxes));
        for (const ch of checkboxes) {
            ch.checked = event.target.checked;
            this.selectAllcheckBox = ch.checked;
        }
        this.handleChange(event);
    }


    handleChange(event) {
        const { name, checked } = event.target;
        this.checkboxesState = { ...this.checkboxesState, [name]: checked };
        this.regId = event.target.dataset.key;
        var valueset = event.target.checked;
        //console.log('valueset: ' + valueset);
        var fieldName = event.currentTarget.name;
        //console.log('fieldName: ' + fieldName);
        var Name = event.target.dataset.name;
        //console.log('Name: ' + Name);
        if (fieldName === undefined) {
            for (var i = this.pageSize * this.currentPage - this.pageSize; i < this.pageSize * this.currentPage; i++) {
                this.currentPageData[i].isSelected = false;
            }
        } else if (fieldName == 'SelectAll') {
            if (this.selectAllcheckBox == true) {
                for (var i = this.pageSize * this.currentPage - this.pageSize; i < this.pageSize * this.currentPage; i++) {
                    for (var i = 0; i < this.currentPageData.length; i++) {
                        const value = this.currentPageData[i].demand.Id;
                        this.currentPageData[i].isSelected = true;
                        if (!this.mainList.includes(value)) {
                            this.mainList.push(value);
                        }
                    }
                    break;
                }
            } else {
                for (var i = this.pageSize * this.currentPage - this.pageSize; i < this.pageSize * this.currentPage; i++) {
                    for (var j = 0; j < this.currentPageData.length; j++) {
                        const value = this.currentPageData[j].demand.Id;
                        this.currentPageData[j].isSelected = false;
                        if (this.mainList.includes(value)) {
                            const index = this.mainList.indexOf(value);
                            if (index !== -1) {
                                this.mainList.splice(index, 1);
                            }
                        }
                    }
                    break;
                }
            }
        } else {
            for (var i = 0; i < this.selectedList.length; i++) {
                const value = this.selectedList[i].demand.Id;
                // if (!this.selectedList[i].isDownloaded) {
                if (value == this.regId) {
                    if (valueset == true) {
                        this.mainList.push(value);
                        // this.url.push(Name);
                    } else {
                        this.mainList = this.mainList.filter(finalItem => finalItem !== this.regId);
                        // this.url = this.url.filter(finalItem => finalItem !== Name);
                    }
                }
                // }
            }
            for (var i = 0; i < this.currentPageData.length; i++) {
                if (this.currentPageData[i].demand.Id == this.regId) {
                    this.currentPageData[i].isSelected = valueset;
                    break;
                }
            }
            const allSelected = this.currentPageData.every(record => record.isSelected);
            console.log('allSelected : ' + allSelected);
            this.selectAllcheckBox = allSelected;
        }
        console.log('currentPageDataUpdated: ' + JSON.stringify(this.currentPageData));
        console.log('FinalMainList: ' + JSON.stringify(this.mainList));

    }

    handlePreviousPage() {
        this.isSpinner = true;
        this.currentPage = Math.max(1, this.currentPage - 1);
        this.index = ((this.currentPage - 1) * this.pageSize);
        this.isSpinner = false;
        var allSelected = true;
        for (var i = 0; i < this.currentPageData.length; i++) {
            if (!this.currentPageData[i].isSelected) {
                allSelected = false;
                break;
            }
        }
        this.selectAllcheckBox = allSelected;
    }


    handleNextPage() {
        this.isSpinner = true;
        this.currentPage = Math.min(this.totalPages, this.currentPage + 1);
        this.index = ((this.currentPage - 1) * this.pageSize);
        this.isSpinner = false;
        var allSelected = true;
        for (var i = 0; i < this.currentPageData.length; i++) {
            if (!this.currentPageData[i].isSelected) {
                allSelected = false;
                break;
            }
        }
        this.selectAllcheckBox = allSelected;
    }


    handleReset() {
        setTimeout(() => {
            location.reload();
        }, 1000);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

     // Show modal and start auto-close timer
     showModalWithRecords(title, records, showmodal) {
        this.modalTitle = title;
        this.modalRecords = records;
        this.showModal = showmodal;

        // Clear any previous timers
        clearTimeout(this.autoCloseTimeout);

        // Auto close after 5 seconds
        this.autoCloseTimeout = setTimeout(() => {
            this.closeModal();
        }, 5000);
    }

    // Manual close method
    closeModal() {
        this.showModal = false;
        clearTimeout(this.autoCloseTimeout);
    }


}