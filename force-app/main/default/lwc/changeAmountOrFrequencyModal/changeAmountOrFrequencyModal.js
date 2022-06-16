import { LightningElement, api, track } from 'lwc';
import changeAmountOrFrequency from '@salesforce/label/c.changeAmountOrFrequency';
import updateRecurringDonation from '@salesforce/label/c.updateRecurringDonation';
import every from "@salesforce/label/c.RD2_EntryFormScheduleEveryLabel";
import commonAmount from "@salesforce/label/c.commonAmount";
import installmentPeriod from "@salesforce/label/c.installmentPeriod";
import recurringDonationSchedule from "@salesforce/label/c.recurringDonationSchedule";
import RECURRING_DONATION from '@salesforce/schema/npe03__Recurring_Donation__c';
import AMOUNT_FIELD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import INSTALLMENT_FREQUENCY_FIELD from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import INSTALLMENT_PERIOD_FIELD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import MONTH_DAY_FIELD from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = "Escape";
const FOCUSABLE_ELEMENTS = "button";
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = "Tab";
export default class ChangeAmountOrFrequencyModal extends LightningElement {
    @api openChangeAmountOrFrequency;
    @api currentRecord;
    isRenderCallbackActionExecuted = false;

    @track isMonthlyDonation = false;

    recurringDonationApiName = RECURRING_DONATION;
    amountFieldName = AMOUNT_FIELD;
    installmentFrequencyFieldName = INSTALLMENT_FREQUENCY_FIELD;
    installmentPeriodFieldName = INSTALLMENT_PERIOD_FIELD;
    dayOfMonthFieldName = MONTH_DAY_FIELD;
    style = document.createElement('style');

    labels = {
        changeAmountOrFrequency,
        updateRecurringDonation,
        every,
        commonAmount,
        recurringDonationSchedule,
        installmentPeriod
    }

    renderedCallback() {
        if (this.isRenderCallbackActionExecuted) {
            return;
        }
        if(this.currentRecord ){
            if(this.currentRecord !== {}){
                this.template.addEventListener("keydown", (e) => this.handleKeyUp(e));
                this.style.innerText = `lightning-helptext {
                    display:none;
                }`;
                if(this.template.querySelector('lightning-record-edit-form')){
                    this.template.querySelector('lightning-record-edit-form').appendChild(this.style);
                }
                if( this.currentRecord.recurringDonation.Day_of_Month__c ){
                    this.isMonthlyDonation = true;
                }else{
                    this.isMonthlyDonation = false;
                }
                this.isRenderCallbackActionExecuted=true;
            }
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

      handleInstallmentPeriodChange(event){
        console.log(event.target.value);
        if((event.target.value) === "Monthly"){
            this.isMonthlyDonation = true;
        }
      }
  
      _getFocusableElements() {
        const potentialElems = [
          ...this.template.querySelectorAll(FOCUSABLE_ELEMENTS),
        ];
        return potentialElems;
      }
  
      closeModal() {
        this.isRenderCallbackActionExecuted = false;
        this.template.removeEventListener("keydown", (e) => this.handleKeyUp(e));       
        if(this.template.querySelector('lightning-record-edit-form')){
            this.style.innerText = `lightning-helptext {
                display:none;
            }`;
            this.template.querySelector('lightning-record-edit-form').removeChild(this.style);
        }

        this.dispatchEvent(new CustomEvent('close', {detail: 'changeAmountOrFrequency'}));
    } 
}