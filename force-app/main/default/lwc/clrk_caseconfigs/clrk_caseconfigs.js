import { LightningElement, track, wire,api } from 'lwc';
import { publish,subscribe,unsubscribe,APPLICATION_SCOPE,MessageContext} from "lightning/messageService";  
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ISCLOSED_FIELD from '@salesforce/schema/Case.IsClosed';
import CONFIGDATASERVICE from "@salesforce/messageChannel/CLRK_SendConfigsData__c";
import getAllCaseConfigsLst from '@salesforce/apex/CLRK_ConfigsController.getAllCaseConfigs';
import sendCaseConfigs from '@salesforce/apex/CLRK_ConfigsController.handleCaseSend';
import addConfigs from '@salesforce/apex/CLRK_ConfigsController.addConfigsToCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


const fields = [ISCLOSED_FIELD];

export default class Clrk_caseconfigs extends LightningElement {
	    	
	@api recordId;
	error;
	@track allCaseConfigsLst = [];
	@track tempList = [];
	@track showCheckBoxColumn = false;
    subscription = null;
    @track receivedMessage;
    addDisabled = false;
	labelName = 'Case Configs (0)';

	@wire(MessageContext) messageContext;

	@wire(getRecord, { recordId: '$recordId', fields })
    case({ error, data}) {
		if( data ){			
			this.addDisabled  = data.fields[ ISCLOSED_FIELD.fieldApiName ].value;							
		}
		  else if( error ){
			console.error( "error: ", error );
		  }	  
	}
    connectedCallback() {
		this.handleSubscribe();		
		this.getAllCaseConfigs();
	}	
	getAllCaseConfigs(){
		//Calling apex controller to get all case records
		getAllCaseConfigsLst({caseId: this.recordId})
		.then(result => {
			console.log('result---->c/clrk_availableconfigs'+JSON.stringify(result));
			//Upon successful insertion, adding items to js list
			if(result.length > 0){
				this.allCaseConfigsLst = JSON.parse(JSON.stringify(result));
				this.labelName = 'Case Configs ('+this.allCaseConfigsLst.length+')';
			}	
		})
		.catch(error => {
			this.error = error;
		});
	}
	handleSubscribe(){
		var tempList = [];

		if (this.subscription) {
			return;
		}
		this.subscription = subscribe(this.messageContext, CONFIGDATASERVICE, (message) => {
			
			this.receivedMessage = message;			
			if(this.receivedMessage.source === 'availableConfigs' && this.receivedMessage.recordId === this.recordId &&  this.receivedMessage.recordData.length > 0){
				tempList = this.receivedMessage.recordData;
				console.log('tempList is--->'+JSON.stringify(tempList));
			}
			if(tempList.length > 0){
			
			//Calling apex controller to insert the case records
			addConfigs({configsLst: tempList,caseId: this.recordId})
			.then(result => {
				//Upon successful insertion, adding items to js list

				tempList.forEach(element => {
					let caseObj = {
						Label__c: element.Label__c,
						Id: element.Id,
						Amount__c : element.Amount__c,
						Type__c : element.Type__c,
						Case__c: this.recordId
					};
					this.allCaseConfigsLst.push(caseObj);
					
				});
				tempList = [];
				this.labelName = 'Case Configs ('+this.allCaseConfigsLst.length+')';				
			})
			.catch(error => {
				this.showToast('Failure','Error while sending the case configs','error');
				this.error = error;
			});
				
			}			
		});
		
	}
	sendSelectedItems(){

		this.addDisabled = true;
		const message = {
            recordId: this.recordId,
            recordData: this.allCaseConfigsLst,
            source: "caseConfigs",
			sendData: true    
        };
        publish(this.messageContext, CONFIGDATASERVICE, message);
		console.log('i sent the message');

		sendCaseConfigs({caseConfigsLst: this.allCaseConfigsLst,caseId: this.recordId})
			.then(result => {
				this.showToast('Success','All the case configs sent successfully','success');
			})
			.catch(error => {
				this.showToast('Failure','Error while sending the case configs','error');
				this.error = error;				
			});

	}
	showToast(title,message,variant) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant,
			mode: 'dismissable'
		});
		this.dispatchEvent(event);
	}

}