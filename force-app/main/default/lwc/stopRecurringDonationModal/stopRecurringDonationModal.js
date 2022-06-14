import { LightningElement, api } from 'lwc';
import stopRecurringDonation from '@salesforce/label/c.stopRecurringDonation';
import stopRecurringDonationModalTitle from '@salesforce/label/c.stopRecurringDonationModalTitle';
import cancelDonation from '@salesforce/apex/RD2_ETableController.cancelDonation';
import RD2_ElevateRDCancellingTitle from '@salesforce/label/c.RD2_ElevateRDCancellingTitle';
import RD2_ElevateRDCancellingMessage from '@salesforce/label/c.RD2_ElevateRDCancellingMessage';
import RD2_NonElevateRDCancellingTitle from '@salesforce/label/c.RD2_NonElevateRDCancellingTitle';
import commonClose from '@salesforce/label/c.commonClose';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = "Escape";
const FOCUSABLE_ELEMENTS = "button";
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = "Tab";
export default class StopRecurringDonationModal extends LightningElement {

    labels = {
        stopRecurringDonation,
        stopRecurringDonationModalTitle,
        commonClose
    }
    isElevate = true;
    @api openStopRecurringDonation;
    @api currentRecord;

    /**
     * @description Returns title label for toast based on elevate or non elevate RD
     */
    get title() {
      if (this.isElevate) {
          return RD2_ElevateRDCancellingTitle;
      }
      return RD2_NonElevateRDCancellingTitle;
    }

    /**
     * @description Returns message label for toast based on elevate or non elevate RD
     */
    get message() {
      if (this.isElevate) {
          return RD2_ElevateRDCancellingMessage;
      }
      return '';
    }

    renderedCallback() {
        this.template.addEventListener("keydown", (e) => this.handleKeyUp(e));
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
      
      handleCancelDonation(){
        cancelDonation({ recurringDonationId: this.currentRecord.recurringDonation.Id})
          .then(() => {
            const event = new ShowToastEvent({
                title: this.title,
                message: this.message
            });
            this.dispatchEvent(event);
          })
        this.closeModal();
      } 
  
      closeModal() {
        this.template.removeEventListener("keydown", (e) => this.handleKeyUp(e));
        this.dispatchEvent(new CustomEvent('close', {detail: 'stopRecurringDonation'}));
      } 
}