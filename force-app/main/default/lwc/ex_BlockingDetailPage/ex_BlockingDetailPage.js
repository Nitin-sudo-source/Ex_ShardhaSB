import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import createBlockingRecord from '@salesforce/apex/Ex_BlockingDetailsController.createBlockingRecord'
import unblockLogic from '@salesforce/apex/Ex_BlockingDetailsController.unblockLogic';
import fetchUnits from '@salesforce/apex/Ex_BlockingDetailsController.fetchUnits';
import getBlockDetails from '@salesforce/apex/Ex_BlockingDetailsController.getBlockDetails';
import getOppName from '@salesforce/apex/Ex_BlockingDetailsController.getOppName';
import getModeOfFundingPicklist from '@salesforce/apex/Ex_BlockingDetailsController.getModeOfFundingPicklist';
import { NavigationMixin } from "lightning/navigation";

export default class Ex_BlockingDetailPage extends NavigationMixin(LightningElement) {
    @track blockData;
  selected = null;
  unblockComment;
  clickBtn = '';
  boolVisible = false;
  units = [];
  untNm = '';
  blockComment;
  blockWithoutTokenCheckbox = false;
  blockWithTokenCheckbox = false;
  blockWithoutTokenCheckbox1 = false;
  @track blockWithTokenCheckbox1 = false;
  blockAmount;
  @track blockId;
  @track chequeNo = '';
  @track unitTrue = true;
  @api uniValue;
  @api oppvalue;
  @api projValue;
  @track projectName;
  @track towerName;
  @track oppName;
  @track blockAmount1 = 0;
  @track MOPpicklist = [];
  @track MOPpicklistValue = ''
  connectedCallback() {
    console.log('Received uId in ex_CreateQuate:', this.uniValue);
    console.log('Received pId in ex_CreateQuate:', this.projValue);
    console.log('Received oId in ex_CreateQuate:', this.oppvalue);

  }
  @wire(getModeOfFundingPicklist)
  wiredPicklistValues({ error, data }) {
      if (data) {
          this.MOPpicklist = data.Mode_of_Payment__c.map(item => ({
              label: item,
              value: item
          }));
        }
      }
  @wire(fetchUnits, { uniId: '$uniValue' })
  units({ data, error }) {
    if (data) {
      this.units = data;
       this.untNm = this.units[0].Name;
       this.projectName = this.units[0].Project__r.Name;
       this.towerName = this.units[0].Tower__r.Name
      console.log(this.units[0].Sale_Status__c);
      if (this.units[0].Sale_Status__c == 'Vacant') {
        this.unitTrue = false;
        this.clickBtn = 'Confirm Blocking'
      } else {
        this.unitTrue = true;
        this.clickBtn = 'Unblock'
      }
    }
    if (error) {
      console.error(error);
    }
  }
  @wire(getOppName, { oppId: '$oppvalue' })
  opportunity__c({ data, error }) {
    if (data) {
      this.oppName = data[0].Name;
    }
  }
  @wire(getBlockDetails, { uniId: '$uniValue' })
  blockdetail({ data, error }) {
    // alert('called');
    if (data != null) {
        console.log('data: '+JSON.stringify(data));
        this.blockData = data;
        console.log(' blockData', JSON.stringify(this.blockData));
        this.blockId = data.Id;
        console.log(' blockId: ', JSON.stringify(this.blockId));
        this.blockWithTokenCheckbox = data.Blocked_with_token__c;
        console.log(' blockWithTokenCheckbox: ', JSON.stringify(this.blockWithTokenCheckbox));
        this.blockAmount = data.Amount__c;
        console.log(' blockAmount: ', JSON.stringify(this.blockAmount));
        this.chequeNo = data.Transaction_ID__c;
        console.log(' chequeNo: ', JSON.stringify(this.chequeNo));
        this.blockComment = data.Blocking_Comments__c;
        console.log(' blockComment: ', JSON.stringify(this.blockComment));
    }else{
        console.log('error: '+JSON.stringify(error));
    }
  }

  BlockWithTokenHandler(event) {
    this.blockWithTokenCheckbox1 = event.target.checked;
  }
  amountHandler(event) {
    this.blockAmount1 = event.target.value;
  }
  chequeNoHandler(event) {
    this.chequeNo = event.target.value;
  }
  commentHandler(event) {
    this.blockComment = event.target.value;
  }
  commentHandler(event) {
    this.blockComment = event.target.value;
  }
  UnblockcommentHandler(event) {
    this.unblockComment = event.target.value;
  }
  handleMOPChange(event){
    this.MOPpicklistValue = event.target.value; 
    console.log(this.MOPpicklistValue);
  }
  BlockingHandler(event) {
    this.selected = this.clickBtn;
    if (this.selected === 'Confirm Blocking') {
      if (this.blockWithTokenCheckbox1 === true && ((this.blockAmount1 == 0 || this.blockAmount1 === '' )  || (this.MOPpicklistValue === undefined || this.MOPpicklistValue === '')  || (this.chequeNo === undefined || this.chequeNo === ''))) {
        const event = new ShowToastEvent({
          title: 'Error !!',
          message: 'Please Enter Amount , Mode of Payment and Transaction ID !',
          variant: 'error',
          mode: 'dismissable'
        });
        this.dispatchEvent(event);
      }else if(this.blockComment === undefined || this.blockComment === ''){
        const event = new ShowToastEvent({
          title: 'Error !!',
          message: 'Please Enter Block Comment!',
          variant: 'error',
          mode: 'dismissable'
        });
        this.dispatchEvent(event);
      }
      else{
        createBlockingRecord({ blockByToken: this.blockWithTokenCheckbox1, amount: this.blockAmount1, blockComment: this.blockComment, chequeNo: this.chequeNo, unitName: this.uniValue, oppId: this.oppvalue ,MOPpicklistValue :this.MOPpicklistValue})
          .then((result) => {
              this.showToastMsg('Success', 'Blocking record created successfully');
              var compDefinition = {
                componentDef: "c:ex_InventoryMatrix",
                attributes: {
                    oppId: this.oppvalue
                }
              };
              var encodedCompDef = btoa(JSON.stringify(compDefinition));
              var url = "/one/one.app#" + encodedCompDef;
              console.log(url);

              var link = document.createElement('a');
              link.href = url;
              link.target = '_self';
              link.click();
              location.reload();
              // window.location.href = '/apex/Ex_InventoryMatrixVF?recordId=' + this.oppvalue;
              console.log("BlockingDetailResult: ", result);
            getRecordNotifyChange([{ recordId: this.recordId }])
          }).catch(error => {
            this.showToastMsg('Error in creating  blocking record', error.body.message, error)
            console.error(error);
          })
        if ((this.blockWithTokenCheckbox1 === true && this.blockAmount != null && this.chequeNo != null)) {
          this.boolVisible = true;
        }
      }
    
    } else if (this.selected === 'Unblock') {
      if (!this.unblockComment) {
        const event = new ShowToastEvent({
          title: 'Error  !!',
          message: 'Please Enter Unblock Comment!',
          variant: 'error',
          mode: 'dismissable'
        });
        this.dispatchEvent(event);
      } else {
        unblockLogic({ blockId: this.blockId, unblockComment: this.unblockComment }).then((result) => {
          console.log("UnblockResult: ", JSON.stringify(result));
          if (this.unblockComment) {
            this.showToastMsg('Success!!', 'block and unit status updated successfully!');
            var compDefinition = {
              componentDef: "c:ex_InventoryMatrix",
              attributes: {
                oppId: this.oppvalue
              }
            };
            
            var encodedCompDef = btoa(JSON.stringify(compDefinition));

            var url = "/one/one.app#" + encodedCompDef;
            console.log(url);

            var link = document.createElement('a');
            link.href = url;
            link.target = '_self';
            link.click();
             location.reload();

            // window.location.href = '/apex/Ex_InventoryMatrixVF?recordId=' + this.oppvalue;
          }

        }).catch(error => {
          this.showToastMsg('Error in updating record', error.body.message, error);
          console.error(error);
        })
        this.boolVisible = false;
      }
    }
  }

  showToastMsg(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant || 'Success'
      })
    )
  }

}