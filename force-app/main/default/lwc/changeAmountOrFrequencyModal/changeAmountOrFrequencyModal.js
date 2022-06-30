import { LightningElement, api, wire } from "lwc";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import changeAmountOrFrequency from "@salesforce/label/c.changeAmountOrFrequency";
import updateRecurringDonation from "@salesforce/label/c.updateRecurringDonation";
import every from "@salesforce/label/c.RD2_EntryFormScheduleEveryLabel";
import commonAmount from "@salesforce/label/c.commonAmount";
import installmentPeriod from "@salesforce/label/c.installmentPeriod";
import recurringDonationSchedule from "@salesforce/label/c.recurringDonationSchedule";
import RECURRING_DONATION from "@salesforce/schema/npe03__Recurring_Donation__c";
import AMOUNT_FIELD from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c";
import INSTALLMENT_FREQUENCY_FIELD from "@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c";
import INSTALLMENT_PERIOD_FIELD from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c";
import INSTALLMENT_NUMBER_FIELD from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c";
import commonCancelAndClose from "@salesforce/label/c.commonCancelAndClose";
import commonCancel from "@salesforce/label/c.commonCancel";
import INSTALLMENT_PERIOD_FIELD_VALUES from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c";

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = "Escape";
const FOCUSABLE_ELEMENTS = "button";
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = "Tab";
const FIXED_RD2_TYPE = "Fixed";
const FIRST_AND_FIFTEENTH = "1st and 15th";

export default class ChangeAmountOrFrequencyModal extends LightningElement {
    @api defaultRecordTypeId;
    @api openChangeAmountOrFrequency;
    @api currentRecord;
    @api fixedInstallmentsLabel;

    installmentPeriodPicklistOptions;

    isRenderCallbackActionExecuted = false;
    isFixedDonation = false;

    recurringDonationApiName = RECURRING_DONATION;
    amountFieldName = AMOUNT_FIELD;
    installmentFrequencyFieldName = INSTALLMENT_FREQUENCY_FIELD;
    installmentPeriodFieldName = INSTALLMENT_PERIOD_FIELD;
    installmentNumberFieldName = INSTALLMENT_NUMBER_FIELD;
    style = document.createElement("style");

    labels = {
        changeAmountOrFrequency,
        updateRecurringDonation,
        every,
        commonAmount,
        recurringDonationSchedule,
        installmentPeriod,
        commonCancelAndClose,
        commonCancel,
    };

    @wire(getPicklistValues, { recordTypeId: "$defaultRecordTypeId", fieldApiName: INSTALLMENT_PERIOD_FIELD_VALUES })
    installmentPeriodPicklistValues({ data, error }) {
        if (data) {
            this.installmentPeriodPicklistOptions = data.values.filter((el) => el.value !== FIRST_AND_FIFTEENTH);
        }
    }

    renderedCallback() {
        if (this.isRenderCallbackActionExecuted) {
            return;
        }
        if (this.currentRecord) {
            if (this.currentRecord !== {}) {
                this.template.addEventListener("keydown", (e) => this.handleKeyUp(e));
                this.style.innerText = `lightning-helptext {
                    display:none;
                }`;
                if (this.template.querySelector("lightning-record-edit-form")) {
                    this.template.querySelector("lightning-record-edit-form").appendChild(this.style);
                    if (this.currentRecord.recurringDonation.RecurringType__c === FIXED_RD2_TYPE) {
                        this.isFixedDonation = true;
                    }
                }
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
        } else if (e.code === ESC_KEY_STRING || e.keyCode === ESC_KEY_CODE) {
            this.closeModal();
        } else if (e.code === TAB_KEY_STRING || e.keyCode === TAB_KEY_CODE) {
            if (this.template.activeElement === lastFocusableElement) {
                firstFocusableElement.focus();
                e.preventDefault();
            }
        }
    }

    handleInstallmentPeriodChange(event) {
        this.currentRecord.recurringDonation.npe03__Installment_Period__c = event.detail.value;
    }

    _getFocusableElements() {
        const potentialElems = [...this.template.querySelectorAll(FOCUSABLE_ELEMENTS)];
        return potentialElems;
    }

    closeModal() {
        this.template.removeEventListener("keydown", (e) => this.handleKeyUp(e));
        if (this.template.querySelector("lightning-record-edit-form")) {
            this.style.innerText = `lightning-helptext {
                display:none;
            }`;
            this.template.querySelector("lightning-record-edit-form").removeChild(this.style);
        }
        this.isFixedDonation = false;
        this.isRenderCallbackActionExecuted = false;
        this.dispatchEvent(new CustomEvent("close", { detail: "changeAmountOrFrequency" }));
    }
}
