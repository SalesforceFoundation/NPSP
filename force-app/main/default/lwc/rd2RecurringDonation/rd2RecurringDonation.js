/* eslint-disable vars-on-top */
import { LightningElement, api, wire, track } from "lwc";
import commonAmount from "@salesforce/label/c.commonAmount";
import RDCL_Frequency from "@salesforce/label/c.RDCL_Frequency";
import lblStatus from "@salesforce/label/c.lblStatus";
import RD_firstDonation from "@salesforce/label/c.RD_firstDonation";
import RD_finalDonation from "@salesforce/label/c.RD_finalDonation";
import RD_nextDonation from "@salesforce/label/c.RD_nextDonation";
import RD_mostRecentDonation from "@salesforce/label/c.RD_mostRecentDonation";
import RD_lastModified from "@salesforce/label/c.RD_lastModified";
import RD2_ViewMoreDetails from "@salesforce/label/c.RD2_ViewMoreDetails";
import RD2_ViewLessDetails from "@salesforce/label/c.RD2_ViewLessDetails";
import updatePaymentMethod from "@salesforce/label/c.updatePaymentMethod";
import changeAmountOrFrequency from "@salesforce/label/c.changeAmountOrFrequency";
import stopRecurringDonation from "@salesforce/label/c.stopRecurringDonation";
import RD2_Actions from "@salesforce/label/c.RD2_Actions";
import retrieveTableView from "@salesforce/apex/RD2_ETableController.retrieveTableView";
import TIME_ZONE from '@salesforce/i18n/timeZone';
import CURRENCY from '@salesforce/i18n/currency';

import RECURRING_DONATION from "@salesforce/schema/npe03__Recurring_Donation__c";
import FIELD_COMMITMENT_ID from "@salesforce/schema/npe03__Recurring_Donation__c.CommitmentId__c";
import FIELD_PAYMENT_METHOD from "@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c";
import FIELD_DAY_OF_MONTH from "@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c";
import FIELD_INSTALLMENTS from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c";

import { getObjectInfo } from "lightning/uiObjectInfoApi";
import FORM_FACTOR from "@salesforce/client/formFactor";

const FormFactorType = Object.freeze({
    Large: "Large",
    Medium: "Medium",
    Small: "Small",
});

const MOBILE_CLASSES_ROW = "slds-truncate dv-dynamic-width dv-dynamic-mobile";
const DESKTOP_CLASSES_ROW = "slds-truncate dv-dynamic-width td-dynamic-width";
const MOBILE_CLASSES_HEAD = "slds-is-resizable dv-dynamic-width dv-dynamic-mobile";
const DESKTOP_CLASSES_HEAD = "slds-is-resizable dv-dynamic-width th-dynamic-width";
const MOBILE_VIEW_MORE = "viewMore";
const DESKTOP_VIEW_MORE = "slds-hide";
const MOBILE_HEADER_CLASS = "slds-border_right slds-border_left th-padding-top";
const DESKTOP_HEADER_CLASS = "slds-table_header-fixed_container slds-border_right slds-border_left th-padding-top";
const CLOSED_STATUS = "Closed";
const MONTHLY = "Monthly";

export default class RecurringDonationTable extends LightningElement {
    openUpdatePaymentMethod = false;
    openChangeAmountOrFrequency = false;
    openStopRecurringDonation = false;
    currentRecord;
    fixedInstallmentsLabel;
    isElevateDonation = false;
    isInitiallyMonthlyDonation = false;
    paymentMethodLabel;
    dayOfMonthFieldLabel;
    defaultRecordTypeId;

    @api
    donationTypeFilter;

    @api
    allowACHPaymentMethod;

    @track tdClasses = "hide-td";
    @track tdClassesNotHidden= "";
    @track actionClasses = "dv-dynamic-width"

    formFactor = FORM_FACTOR;

    lastDonationDate = "";

    labels = {
        commonAmount,
        RDCL_Frequency,
        lblStatus,
        RD_firstDonation,
        RD_finalDonation,
        RD_mostRecentDonation,
        RD_nextDonation,
        RD_lastModified,
        RD2_ViewMoreDetails,
        RD2_ViewLessDetails,
        RD2_Actions,
    };

    data;

    actions = [
        { label: updatePaymentMethod, name: "updatePaymentMethod", disabled: false },
        { label: changeAmountOrFrequency, name: "changeAmountOrFrequency", disabled: false },
        { label: stopRecurringDonation, name: "stopRecurringDonation", disabled: false },
    ];

    columns = [];
    timeZone = TIME_ZONE;
    currency = CURRENCY;

    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION })
    oppInfo({ data, error }) {
        if (data) {
            this.paymentMethodLabel = data.fields[FIELD_PAYMENT_METHOD.fieldApiName].label;
            this.dayOfMonthFieldLabel = data.fields[FIELD_DAY_OF_MONTH.fieldApiName].label;
            this.fixedInstallmentsLabel = data.fields[FIELD_INSTALLMENTS.fieldApiName].label;
            this.defaultRecordTypeId = data.defaultRecordTypeId;
            this.getRecurringDonationFields();
        }
    }

    connectedCallback() {
      if(!this.isMobile){
        this.tdClasses = "td-dynamic-width";
        this.tdClassesNotHidden = "td-dynamic-width";
        this.actionClasses = "lastColumn dv-dynamic-width";
      }
      this.template.addEventListener('keydown', (event) => {
        let cells   = this.template.querySelectorAll("[tabindex='-1']");
        let active  = Array.prototype.indexOf.call(cells, event.target);
        let columns = this.template.querySelectorAll('tr th').length;
        if (event.keyCode === 37) {
            active = (active > 0) ? active - 1 : active;
        }
        if (event.keyCode === 38) {
            active = (active - columns >= 0) ? active - columns : active;
        }
        if (event.keyCode === 39) {
            active = (active < cells.length - 1) ? active + 1 : active;
        }
        if (event.keyCode === 40) {
            active = (active + columns <= cells.length - 1) ? active + columns : active;
        }
        let activeTDs = this.template.querySelectorAll('.slds-has-focus');
        for (let i = 0; i < activeTDs.length; i++) {
            activeTDs[i].classList.remove('slds-has-focus');
        }
        cells[active].classList.add('slds-has-focus');
        cells[active].focus();
      });
    }
  
    /**
     * @description Returns whether we are running in mobile or desktop
     * @returns True if it is mobile
     */
    get isMobile() {
        return this.formFactor === FormFactorType.Small || this.formFactor === FormFactorType.Medium;
    }

    /**
     * @description Returns the classes to be applied to the rows according if it is mobile or desktop
     */
    get rowClasses() {
        if (this.isMobile) {
            return MOBILE_CLASSES_ROW;
        }
        return DESKTOP_CLASSES_ROW;
    }

    /**
     * @description Returns the classes to be applied to the rows according if it is mobile or desktop
     */
    get viewMore() {
        if (this.isMobile) {
            return MOBILE_VIEW_MORE;
        }
        return DESKTOP_VIEW_MORE;
    }

    /**
     * @description Returns the classes to be applied to the rows according if it is mobile or desktop
     */
    get headerClass() {
        if (this.isMobile) {
            return MOBILE_HEADER_CLASS;
        }
        return DESKTOP_HEADER_CLASS;
    }

    /**
     * @description Returns the classes to be applied to the headers according if it is mobile or desktop
     */
    get headClasses() {
        if (this.isMobile) {
            return MOBILE_CLASSES_HEAD;
        }
        return DESKTOP_CLASSES_HEAD;
    }

    handlemouseup(e) {
        this._tableThColumn = undefined;
        this._tableThInnerDiv = undefined;
        this._pageX = undefined;
        this._tableThWidth = undefined;
    }

    handlemousedown(e) {
        this._tableThColumn = e.target.parentElement;
        this._tableThInnerDiv = e.target.parentElement;
        
        while (this._tableThColumn.tagName !== "TH") {
            this._tableThColumn = this._tableThColumn.parentNode;
        }
        while (!this._tableThInnerDiv.className.includes("cell")) {
            this._tableThInnerDiv = this._tableThInnerDiv.parentNode;
        }
        this._pageX = e.pageX ? e.pageX : e.changedTouches[0].pageX;

        this._padding = this.paddingDiff(this._tableThColumn);

        this._tableThWidth = this._tableThColumn.offsetWidth - this._padding;
    }

    handlemousemove(e) {
        if (this._tableThColumn && this._tableThColumn.tagName === "TH") {
            this._diffX = (e.pageX ? e.pageX : e.changedTouches[0].pageX) - this._pageX;
            if((this._tableThWidth + this._diffX) > 50){
                this._tableThColumn.style.width = this._tableThWidth + this._diffX + "px";
                this._tableThInnerDiv.style.width = this._tableThColumn.style.width;
                let tableThs = this.template.querySelectorAll("th");
                let tableBodyRows = this.template.querySelectorAll("table tbody tr");
                tableBodyRows.forEach((row) => {
                    let rowTds = row.querySelectorAll(".dv-dynamic-width");
                    rowTds.forEach((td, ind) => {
                            rowTds[ind].style.width = tableThs[ind].style.width
                    });
                });
            }
        }
    }

    paddingDiff(col) {
        if (this.getStyleVal(col, "box-sizing") === "border-box") {
            return 0;
        }
        this._padLeft = this.getStyleVal(col, "padding-left");
        this._padRight = this.getStyleVal(col, "padding-right");
        return parseInt(this._padLeft, 10) + parseInt(this._padRight, 10);
    }

    getStyleVal(elm, css) {
        return window.getComputedStyle(elm, null).getPropertyValue(css);
    }

    toggleView(event) {
        let tableTd = this.template.querySelectorAll(
            "td[data-id=" + JSON.stringify(event.target.getAttribute("data-viewid")) + "]"
        );
        let viewMoreOrLess = this.template.querySelector(
            "td[data-viewid=" + JSON.stringify(event.target.getAttribute("data-viewid")) + "]"
        );
        if (viewMoreOrLess.getAttribute("data-label") === this.labels.RD2_ViewMoreDetails) {
            viewMoreOrLess.setAttribute("data-label", this.labels.RD2_ViewLessDetails);
        } else {
            viewMoreOrLess.setAttribute("data-label", this.labels.RD2_ViewMoreDetails);
        }
        tableTd.forEach((td) => {
            if (td.classList.contains("hide-td")) {
                td.classList.remove("hide-td");
            } else {
                td.classList.add("hide-td");
            }
        });
    }

    handleRowAction(e) {
        const action = e.target.getAttribute("data-action");
        this.currentRecord = this.data.find((row) => {
            return row.recurringDonation.Id === e.target.getAttribute("data-recordid");
        });

        this.isElevateDonation = this.currentRecord.recurringDonation[FIELD_COMMITMENT_ID.fieldApiName] ? true : false;
        this.isInitiallyMonthlyDonation = this.currentRecord.recurringDonation.npe03__Installment_Period__c === MONTHLY;

        switch (action) {
            case "updatePaymentMethod":
                this.openUpdatePaymentMethod = true;
                break;
            case "changeAmountOrFrequency":
                this.openChangeAmountOrFrequency = true;
                break;
            case "stopRecurringDonation":
                this.openStopRecurringDonation = true;
                break;
            default:
                break;
        }
    }

    handleClose(event) {
        this.currentRecord = {};
        switch (event.detail) {
            case "updatePaymentMethod":
                this.openUpdatePaymentMethod = false;
                break;
            case "changeAmountOrFrequency":
                this.openChangeAmountOrFrequency = false;
                break;
            case "stopRecurringDonation":
                this.openStopRecurringDonation = false;
                break;
            default:
                break;
        }
        this.getRecurringDonationFields();
    }

    getRecurringDonationFields() {
        retrieveTableView({elevateFilter:this.donationTypeFilter}).then((data) => {
            if (data) {
                this.data = data.map((el) => {
                    let isElevate = el.recurringDonation[FIELD_COMMITMENT_ID.fieldApiName] ? true : false;
                    let actions = this.actions
                        .filter((elo) => (elo.name !== "updatePaymentMethod" && !isElevate) || (isElevate))
                        .map((action) => { return { ...action }; });
                    let nexDonationFormatFirstElement = "";
                    let nexDonationFormatSecondElement = "";
                    
                    actions.map((action) => {
                        action.disabled = false;
                        if(el.status === CLOSED_STATUS || (action.name !== 'stopRecurringDonation' && (this.currency !== "USD" && isElevate))) {
                            action.disabled = true;
                        }
                        
                        return action;
                    });
                    el.recurringDonation.npe03__Next_Payment_Date__c = new Date(el.recurringDonation.npe03__Next_Payment_Date__c).toLocaleDateString(undefined, { timeZone: this.timeZone });
                    let lastModifiedDate = new Date(el.recurringDonation.LastModifiedDate).toLocaleDateString(undefined, { timeZone: this.timeZone });
                    return { actions, ...el, nexDonationFormatFirstElement, nexDonationFormatSecondElement, lastModifiedDate };
                });
            }
        });
    }
}