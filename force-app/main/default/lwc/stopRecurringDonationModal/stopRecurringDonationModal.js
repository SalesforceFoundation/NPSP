import { LightningElement, api } from 'lwc';
import stopRecurringDonation from '@salesforce/label/c.stopRecurringDonation';
import stopRecurringDonationModalTitle from '@salesforce/label/c.stopRecurringDonationModalTitle';
import upsertDonation from '@salesforce/apex/RD2_ETableController.upsertDonation';
import RD2_ElevateRDCancellingTitle from '@salesforce/label/c.RD2_ElevateRDCancellingTitle';
import RD2_ElevateRDCancellingMessage from '@salesforce/label/c.RD2_ElevateRDCancellingMessage';
import RD2_NonElevateRDCancellingTitle from '@salesforce/label/c.RD2_NonElevateRDCancellingTitle';
import commonClose from '@salesforce/label/c.commonClose';
import stopRecurringDonationMessage from '@salesforce/label/c.RD2_ElevateRDStopDonationMessage';
import commonCancelAndClose from '@salesforce/label/c.commonCancelAndClose';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = "Escape";
const FOCUSABLE_ELEMENTS = "button";
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = "Tab";
const STATUS_CLOSED = "Closed";
export default class StopRecurringDonationModal extends LightningElement {

    labels = {
        stopRecurringDonation,
        stopRecurringDonationModalTitle,
        commonClose,
        commonCancelAndClose,
        stopRecurringDonationMessage
    }
    isElevate;
    @api openStopRecurringDonation;
    @api currentRecord;
    isFirstRender = true;

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
        this.template.querySelector('[data-id="closeButton"]').focus();
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
            if (this.template.activeElement === lastFocusableElement && !this.isFirstRender) {
              firstFocusableElement.focus();
              e.preventDefault();
            } else if (this.isFirstRender) {
              e.preventDefault();
              focusableContent[1].focus();
              this.isFirstRender = false;
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
        let record = Object.assign({}, this.currentRecord.recurringDonation);
        record.Status__c = STATUS_CLOSED;
        upsertDonation({ recurringDonation: record })
          .then(() => {
            this.isElevate = record.CommitmentId__c ? true : false;
            const event = new ShowToastEvent({
                title: this.title,
                message: this.message
            });
            this.dispatchEvent(event);
            this.closeModal();
          })
      } 
  
      closeModal() {
        this.isFirstRender = true;
        this.template.removeEventListener("keydown", (e) => this.handleKeyUp(e));
        this.dispatchEvent(new CustomEvent('close', {detail: 'stopRecurringDonation'}));
      } 
}