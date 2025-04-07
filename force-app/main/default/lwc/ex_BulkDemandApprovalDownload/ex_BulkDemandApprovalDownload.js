/**
 * @description       : 
 * @author            : nitinSFDC@exceller.SFDoc
 * @group             : 
 * @last modified on  : 07-04-2025
 * @last modified by  : nitinSFDC@exceller.SFDoc
**/
import { LightningElement, api, wire, track } from 'lwc';
import getProject from '@salesforce/apex/Ex_BulkDemandApprovalDashboard.getProject';
import getTower from '@salesforce/apex/Ex_BulkDemandApprovalDashboard.getTower';
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

    @track sortIcons = {
        bookingNo: { icon: 'utility:arrowdown', text: 'ASC', variant: 'success', size: 'small' },
        bookingStatus: { icon: 'utility:arrowdown', text: 'ASC', variant: 'success', size: 'small' },
        registrationDate: { icon: 'utility:arrowdown', text: 'ASC', variant: 'success', size: 'small' },
        UnitName: { icon: 'utility:arrowdown', text: 'ASC', variant: 'success', size: 'small' },
        fileType: { icon: 'utility:arrowdown', text: 'ASC', variant: 'success', size: 'small' }
    };


    @wire(getProject) getProjectData;
    @wire(getTower, { ProjectId: '$projectId' }) getTowerData;

    get projectOptions() {
        return this.getProjectData.data ? this.getProjectData.data.map(p => ({ label: p.Name, value: p.Id })) : [];
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

    //Pagination Logic End

    //Title to Show on Page Start

    get projectTitle() {
        return this.projectId ? 'Project Selected' : 'Please Select Project';
    }

    get towerTitle() {
        return this.towerId ? 'Tower Selected' : 'Please Select Tower';
    }

    get recordSelected() {
        const count = this.mainList.length > 0 ? this.mainList.length : 0;
        if (count > 0) {
            const message = count === 1 ? '1 File has been selected.' : `${count} Files have been selected.`;
            this.showToast('Records Selected', message, 'success');

        }
        // else if(count == 0){
        //     const message = count === 0 ? 'No File has been selected.' : '';
        //     this.showToast('Records Selected', message, 'warning');
        // }
        return count;
    }

    handleProjectChange(event) {
        this.projectId = event.target.value;
        //alert(this.projectId);
    }

    handleTowerChange(event) {
        this.towerId = event.target.value;
        //alert(this.towerId);
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
                        const value = this.currentPageData[i].regId;
                        this.currentPageData[i].isSelected = true;
                        if (!this.mainList.includes(value)) {
                            this.mainList.push(value);
                            if (!this.url.includes(this.currentPageData[i].contentDocumentId)) {
                                this.url.push(this.currentPageData[i].contentDocumentId);
                            }
                        }
                    }
                    break;
                }
            } else {
                //console.log('inside else ');
                for (var i = this.pageSize * this.currentPage - this.pageSize; i < this.pageSize * this.currentPage; i++) {
                    for (var j = 0; j < this.currentPageData.length; j++) {
                        const value = this.currentPageData[j].regId;
                        this.currentPageData[j].isSelected = false;
                        if (this.mainList.includes(value)) {
                            const index = this.mainList.indexOf(value);
                            if (index !== -1) {
                                this.mainList.splice(index, 1);
                            }
                        }
                        if (this.url.includes(this.currentPageData[j].contentDocumentId)) {
                            const index = this.url.indexOf(this.currentPageData[j].contentDocumentId);
                            if (index !== -1) {
                                this.url.splice(index, 1);
                            }
                        }
                    }
                    break;
                }
            }
        } else {
            for (var i = 0; i < this.selectedList.length; i++) {
                const value = this.selectedList[i].regId;
                if (!this.selectedList[i].isDownloaded) {
                    if (value == this.regId) {
                        if (valueset == true) {
                            this.mainList.push(value);
                            this.url.push(Name);
                        } else {
                            this.mainList = this.mainList.filter(finalItem => finalItem !== this.regId);
                            this.url = this.url.filter(finalItem => finalItem !== Name);
                        }
                    }
                }
            }
            for (var i = 0; i < this.currentPageData.length; i++) {
                if (this.currentPageData[i].regId == this.regId) {
                    this.currentPageData[i].isSelected = valueset;
                    break;
                }
            }
        }
        //console.log('currentPageData: ' + JSON.stringify(this.currentPageData));
        console.log('FinalMainList: ' + JSON.stringify(this.mainList));
        //console.log('url ' + JSON.stringify(this.url));

       // this.updateFinalUrl();

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

    
}