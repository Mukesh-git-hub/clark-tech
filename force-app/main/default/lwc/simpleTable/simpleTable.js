import {LightningElement,wire,api,track} from 'lwc';

export default class simpleTable extends LightningElement {

    @api recordlst = [];
    @api hascheckboxselect = false;
    showCheckBoxColumn = false;
    accURL = "";
    isAsc = false;
    isDsc = false;
    isLabelSort = false;
    isTypeSort = false;
    isAmountSort = false;
    error;
    selectAllDisabled = false;
    selectedRecords;
    sortedDirection = 'asc';
    sortedColumn;
    connectedCallback(){
        
    }
    allSelected(event) {
        let selectedRows = this.template.querySelectorAll('lightning-input');
        
        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].type === 'checkbox') {
                selectedRows[i].checked = event.target.checked;
            }
        }
    }
    gotoAccount(event) {
        this.accURL = window.location.origin + "/" + event.currentTarget.dataset.id;
    }

    sortLabel(event) {
        this.isLabelSort = true;
        this.isTypeSort = false;
        this.isAmountSort = false;

        this.sortData(event.currentTarget.dataset.id);
    }
    sortType(event) {
        this.isLabelSort = false;
        this.isTypeSort = true;
        this.isAmountSort = false;
        this.sortData(event.currentTarget.dataset.id);
    }

    sortAmount(event) {
        this.isLabelSort = false;
        this.isTypeSort = false;
        this.isAmountSort = true;

        this.sortData(event.currentTarget.dataset.id);
    }
    sortData(sortColumnName) {
        // check previous column and direction
        if (this.sortedColumn === sortColumnName) {
            this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';
        } 
        else {
            this.sortedDirection = 'asc';
        }

        // check arrow direction
        if (this.sortedDirection === 'asc') {
            this.isAsc = true;
            this.isDsc = false;
        } 
        else {
            this.isAsc = false;
            this.isDsc = true;
        }

        // check reverse direction
        let isReverse = this.sortedDirection === 'asc' ? 1 : -1;

        this.sortedColumn = sortColumnName;
        console.log('sortColumnName--->'+sortColumnName);
        // sort the data
        this.recordlst = JSON.parse(JSON.stringify(this.recordlst)).sort((a, b) => {
            if(sortColumnName == 'Amount__c '){

            }
            a = a[sortColumnName] ? a[sortColumnName].toLowerCase() : ''; // Handle null values
            b = b[sortColumnName] ? b[sortColumnName].toLowerCase() : '';

            return a > b ? 1 * isReverse : -1 * isReverse;
        });;
    }
    @api
    selectedItems() {
        this.selectedRecords = [];
        let selectedRows = this.template.querySelectorAll('lightning-input');
       
        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].checked && selectedRows[i].type === 'checkbox'&& !selectedRows[i].disabled && selectedRows[i].dataset.id != 'selectAll') {
                
                //Making checkboxes disabled
                selectedRows[i].disabled = true;
                this.selectAllDisabled = true;
                
                this.selectedRecords.push({
                    Label__c: selectedRows[i].value,
                    Id: selectedRows[i].dataset.id,
                    Amount__c : selectedRows[i].dataset.amount,
                    Type__c : selectedRows[i].dataset.type                    
                })
            }
        }
        console.log('selectedRecords--->'+JSON.stringify(this.selectedRecords));
        return this.selectedRecords;    
    }
}