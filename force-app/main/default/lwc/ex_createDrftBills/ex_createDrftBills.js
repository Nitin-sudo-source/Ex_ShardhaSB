import { LightningElement, api } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import createDraftBills from '@salesforce/apex/Ex_DraftBillController.createDraftBills';
import {ShowToastEvent} from  'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class Ex_createDrftBills extends LightningElement {

    @api recordId;
    isSpinner = false;

    connectedCallback(){
       
        this.handleConfirmClick();
    }

    async handleConfirmClick() {
        const result = await LightningConfirm.open({
            message: 'Are you sure want to create ?',
            // variant :"headerless",
            label: "Create Draft Bills",
            theme: "success"
        });
        console.log('result ',result);
        console.log('recordId ',this.recordId);
        if(result)
         this.callDraftBillMethod();
        else{
            this.dispatchEvent(new CloseActionScreenEvent());

        }
        
    }
    

    callDraftBillMethod(){
        this.isSpinner = true;
       // alert('draft bill called!');
       createDraftBills({recordId : this.recordId})
        .then(response =>{
            if(response == 'success'){
                // console.log('Draft bills created succesfully !');
                this.showToastMessage('Success','Draft bills will be created !','success');
                this.isSpinner = false;
                this.dispatchEvent(new CloseActionScreenEvent());
            }
            else if(response == 'already'){
                // console.log('Draft bills created succesfully !');
                this.showToastMessage('Warning','Draft bills already created for this termsheet !','warning');
                this.isSpinner = false;
                this.dispatchEvent(new CloseActionScreenEvent());
            }else{
                this.isSpinner = false;
                this.showToastMessage('Error','Please Contact System Admin','error');
                console.log(JSON.stringify(response));
            }
            console.log('response is '+JSON.stringify(response));

        }).catch (error =>{

            // this.isSpinner = false;
            //     this.showToastMessage('Error','Please Contact System Admin','error');
                console.log(JSON.stringify(error));
        })
    }

    showToastMessage(title,message,variant){

        const evt = new ShowToastEvent({
            title : title,
            message : message,
            variant : variant,
        });
        this.dispatchEvent(evt);
    }


}