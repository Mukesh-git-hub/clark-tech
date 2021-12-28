import { LightningElement, track, wire,api } from 'lwc';
import allConfigs from '@salesforce/apex/CLRK_ConfigsController.getAllConfigs';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ISCLOSED_FIELD from '@salesforce/schema/Case.IsClosed';
import { publish, MessageContext , subscribe, unsubscribe, APPLICATION_SCOPE, } from 'lightning/messageService';
import CONFIGDATASERVICE from '@salesforce/messageChannel/CLRK_SendConfigsData__c';

const fields = [ISCLOSED_FIELD];

export default class Clrk_availableconfigs extends LightningElement {
    
    @track allConfigsLst = [];
    @track showCheckBoxColumn = true;
    @track error;
    @api recordId;  
    subscription = null;
    addDisabled = false;
    labelName;

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields })
    case({ error, data}) {
		if( data ){						
			this.addDisabled  = data.fields[ ISCLOSED_FIELD.fieldApiName ].value;
		}
		  else if( error ){
			console.error( "error: ", error );
		  }
	  
	}

    connectedCallback(){
        allConfigs()
            .then(result => {
                this.allConfigsLst = result;
                this.labelName = 'Available Configs ('+result.length+')';
            })
            .catch(error => {
                this.error = error;
            });
        
        this.handleSubscribe();
    }
    addSelectedItems(){
        console.log('the parent');
        const objChild = this.template.querySelector('c-simple-table');
        var selectedLst = objChild.selectedItems();
        console.log('the final list'+JSON.stringify(selectedLst));
        
        const message = {
            recordId: this.recordId,
            recordData: selectedLst,
            source: "availableConfigs",
            sendData: false     
        };
        publish(this.messageContext, CONFIGDATASERVICE, message);
        selectedLst = [];
        console.log('the message has been published');        
    }
    handleSubscribe() {
		if (this.subscription) {
			return;
		}
		this.subscription = subscribe(this.messageContext, CONFIGDATASERVICE, (message) => {
			console.log('getting message');
			this.receivedMessage = message;
			if(this.receivedMessage.source === 'caseConfigs' && 
				this.receivedMessage.recordId === this.recordId &&
				this.receivedMessage.sendData){
				
				this.addDisabled = true;
			}
            console.log('got message');
		});
	}

}