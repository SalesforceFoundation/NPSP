import { LightningElement, api, track } from 'lwc';
import updatePaymentMethod from '@salesforce/label/c.updatePaymentMethod';
import CreditCardPaymentMethod from '@salesforce/label/c.RD2_Credit_Card_Payment_Method_Label';
import ACHPaymentMethodLabel from '@salesforce/label/c.RD2_ACH_Payment_Method_Label';
import paymentMethod from '@salesforce/label/c.RD2_Payment_Method';
import commonCancelAndClose from '@salesforce/label/c.commonCancelAndClose';
import commonCancel from '@salesforce/label/c.commonCancel';

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = "Escape";
const FOCUSABLE_ELEMENTS = "button";
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = "Tab";
const CREDIT_CARD = "Credit Card";
const ACH = "ACH";

export default class UpdatePaymentMethodModal extends LightningElement {
    
    @api isBankPaymentAllowed;
    isRenderCallbackActionExecuted = false;
    @api openUpdatePaymentMethod;
    style = document.createElement('style');
    @api currentRecord;

    labels = {
      updatePaymentMethod,
      commonCancelAndClose,
      commonCancel,
      ACHPaymentMethodLabel,
      CreditCardPaymentMethod,
      commonCancelAndClose,
      commonCancel,
      paymentMethod
    }   

    @track
    paymentMethodOptions = [
        { label: CreditCardPaymentMethod, value: CREDIT_CARD }
    ];


    renderedCallback() {
        if (this.isRenderCallbackActionExecuted) {
            return;
        }
        if(this.currentRecord){
            if(this.currentRecord !== {}){
                this.template.addEventListener("keydown", (e) => this.handleKeyUp(e));
                if(this.template.querySelector('lightning-radio-group')){
                    this.style.innerText = `legend.slds-form-element__legend.slds-form-element__label {
                        padding-bottom: 2%;
                        font-size: 120%;
                    }
                    span.slds-radio {
                        padding-top: 2%;
                        padding-bottom: 2%;
                    }
                    `;
                    this.template.querySelector('lightning-radio-group').appendChild(this.style);
                    this.determineACHpaymentMethodAndAddAsOption();
                }
            }
        }
    }

    determineACHpaymentMethodAndAddAsOption(){
        if(this.isBankPaymentAllowed || this.currentRecord.recurringDonation.PaymentMethod__c === ACH){
            if( !this.paymentMethodOptions.some( element => element.value === ACH) ){
                this.paymentMethodOptions.push( { label: ACHPaymentMethodLabel, value: ACH } );
            }
        } else if (this.paymentMethodOptions.some( element => element.value === ACH)){
            this.paymentMethodOptions.pop( { label: ACHPaymentMethodLabel, value: ACH } );
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
      this.isRenderCallbackActionExecuted = false;
      this.dispatchEvent(new CustomEvent('close', {detail: 'updatePaymentMethod'}));
    }
}