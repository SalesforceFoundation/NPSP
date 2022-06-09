import { LightningElement, api, track } from 'lwc';
import updatePaymentMethod from '@salesforce/label/c.updatePaymentMethod';

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = "Escape";
const FOCUSABLE_ELEMENTS = "button";
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = "Tab";

export default class UpdatePaymentMethodModal extends LightningElement {
    
    @api openUpdatePaymentMethod;
    
    @api currentRecord;

    @track
    paymentMethodValue = "";

    labels = {
      updatePaymentMethod
    }   

    @track
    paymentMethodOptions = [
        { label: 'Credit Card', value: 'Credit Card' }
    ];


    renderedCallback() {
        this.template.addEventListener("keydown", (e) => this.handleKeyUp(e));
        if(this.currentRecord){
            if(this.currentRecord.paymentMethod === "ACH"){
                if( !this.paymentMethodOptions.some( element => element.value === 'ACH') ){
                    this.paymentMethodOptions.push( { label: 'Bank Account', value: 'ACH' } );
                }
            }else if (this.paymentMethodOptions.some( element => element.value === 'ACH')){
                this.paymentMethodOptions.pop( { label: 'Bank Account', value: 'ACH' } );
            }
            this.paymentMethodValue = this.currentRecord.paymentMethod;
        }
    }

    handleKeyUp(e) {
        const firstFocusableElement = this._getFocusableElements()[0];
        const focusableContent = this._getFocusableElements();
        const lastFocusableElement = focusableContent[focusableContent.length - 1];
      
        if (e.shiftKey) {
          if (this.template.activeElement === firstFocusableElement) {
            lastFocusableElement.focus();
            e.preventDefault();
          }
        } else if(e.code === ESC_KEY_STRING || e.keyCode === ESC_KEY_CODE) {
          this.closeModal();
        } else if(e.code === TAB_KEY_STRING || e.keyCode === TAB_KEY_CODE) {
          if (this.template.activeElement === lastFocusableElement) {
            firstFocusableElement.focus();
            e.preventDefault();
          }
        }
    }   

    _getFocusableElements() {
      const potentialElems = [
        ...this.template.querySelectorAll(FOCUSABLE_ELEMENTS),
      ];
      return potentialElems;
    }

    closeModal() {
      this.template.removeEventListener("keydown", (e) => this.handleKeyUp(e));
      this.dispatchEvent(new CustomEvent('close', {detail: 'updatePaymentMethod'}));
    }
}