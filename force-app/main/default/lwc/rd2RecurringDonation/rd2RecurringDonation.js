import { LightningElement, api, wire, track } from "lwc";
import commonAmount from "@salesforce/label/c.commonAmount";
import RDCL_Frequency from "@salesforce/label/c.RDCL_Frequency";
import lblStatus from "@salesforce/label/c.lblStatus";
import firstDonation from "@salesforce/label/c.firstDonation";
import finalDonation from "@salesforce/label/c.finalDonation";
import nextDonation from "@salesforce/label/c.nextDonation";
import mostRecentDonation from "@salesforce/label/c.mostRecentDonation";
import lastModified from "@salesforce/label/c.lastModified";
import RD2_ViewMoreDetails from "@salesforce/label/c.RD2_ViewMoreDetails";
import RD2_ViewLessDetails from "@salesforce/label/c.RD2_ViewLessDetails";
import updatePaymentMethod from "@salesforce/label/c.updatePaymentMethod";
import changeAmountOrFrequency from "@salesforce/label/c.changeAmountOrFrequency";
import stopRecurringDonation from "@salesforce/label/c.stopRecurringDonation";
import RD2_Actions from "@salesforce/label/c.RD2_Actions";
import retrieveTableView from "@salesforce/apex/RD2_ETableController.retrieveTableView";

import RECURRING_DONATION from "@salesforce/schema/npe03__Recurring_Donation__c";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import FORM_FACTOR from "@salesforce/client/formFactor";

const FormFactorType = Object.freeze({
    Large: "Large",
    Medium: "Medium",
    Small: "Small",
});

const MOBILE_CLASSES_ROW = "slds-truncate dv-dynamic-width dv-dynamic-mobile";
const DESKTOP_CLASSES_ROW = "slds-truncate dv-dynamic-width";
const MOBILE_CLASSES_HEAD = "slds-is-resizable dv-dynamic-width dv-dynamic-mobile";
const DESKTOP_CLASSES_HEAD = "slds-is-resizable dv-dynamic-width";
const MOBILE_VIEW_MORE = "viewMore";
const DESKTOP_VIEW_MORE = "slds-hide";
const MOBILE_HEADER_CLASS = "slds-border_right slds-border_left";
const DESKTOP_HEADER_CLASS = "slds-table_header-fixed_container slds-border_right slds-border_left table_top";
const CANCELED_STATUS = "Canceled";

export default class RecurringDonationTable extends LightningElement {
    openUpdatePaymentMethod = false;
    openChangeAmountOrFrequency = false;
    openStopRecurringDonation = false;
    currentRecord;
    fixedInstallmentsLabel;

    defaultRecordTypeId;

    @api
    donationTypeFilter;

    @api
    allowACHPaymentMethod;

    @track tdClasses = "hide-td";

    formFactor = FORM_FACTOR;

    paymentMethod = "";

    fixedWidth = "width:8rem;";

    lastDonationDate = "";

    labels = {

        commonAmount,
        RDCL_Frequency,
        lblStatus,
        firstDonation,
        finalDonation,
        mostRecentDonation,
        nextDonation,
        lastModified,
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

    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION })
    oppInfo({ data, error }) {
        if (data) {
            this.paymentMethod = data.fields.PaymentMethod__c.label;
            this.fixedInstallmentsLabel = data.fields.npe03__Installments__c.label;
            this.defaultRecordTypeId = data.defaultRecordTypeId;
        }
    }

    connectedCallback() {
        this.getRecurringDonationFields();
        if (!this.isMobile) {
            this.tdClasses = "";
        }
    }

    /**
     * @description Returns whether we are running in mobile or desktop
     * @returns True if it is mobile
     */
    get isMobile() {
        return this.formFactor === FormFactorType.Small;
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

    //FOR HANDLING THE HORIZONTAL SCROLL OF TABLE MANUALLY
    tableOuterDivScrolled(event) {
        this._tableViewInnerDiv = this.template.querySelector(".tableViewInnerDiv");
        if (this._tableViewInnerDiv) {
            if (!this._tableViewInnerDivOffsetWidth || this._tableViewInnerDivOffsetWidth === 0) {
                this._tableViewInnerDivOffsetWidth = this._tableViewInnerDiv.offsetWidth;
            }
            this._tableViewInnerDiv.style =
                "width:" +
                (event.currentTarget.scrollLeft + this._tableViewInnerDivOffsetWidth) +
                "px;" +
                this.tableBodyStyle;
        }
        this.tableScrolled(event);
    }

    tableScrolled(event) {
        if (this.enableInfiniteScrolling) {
            if (event.target.scrollTop + event.target.offsetHeight >= event.target.scrollHeight) {
                this.dispatchEvent(
                    new CustomEvent("showmorerecords", {
                        bubbles: true,
                    })
                );
            }
        }
        if (this.enableBatchLoading) {
            if (event.target.scrollTop + event.target.offsetHeight >= event.target.scrollHeight) {
                this.dispatchEvent(
                    new CustomEvent("shownextbatch", {
                        bubbles: true,
                    })
                );
            }
        }
    }

    handlemouseup(e) {
        this._tableThColumn = undefined;
        this._tableThInnerDiv = undefined;
        this._pageX = undefined;
        this._tableThWidth = undefined;
    }

    handlemousedown(e) {
        if (!this._initWidths) {
            this._initWidths = [];
            let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
            tableThs.forEach((th) => {
                this._initWidths.push(th.style.width);
            });
        }

        this._tableThColumn = e.target.parentElement;
        this._tableThInnerDiv = e.target.parentElement;
        while (this._tableThColumn.tagName !== "TH") {
            this._tableThColumn = this._tableThColumn.parentNode;
        }
        while (!this._tableThInnerDiv.className.includes("slds-cell-fixed")) {
            this._tableThInnerDiv = this._tableThInnerDiv.parentNode;
        }
        this._pageX = e.pageX;

        this._padding = this.paddingDiff(this._tableThColumn);

        this._tableThWidth = this._tableThColumn.offsetWidth - this._padding;
    }

    handlemousemove(e) {
        if (this._tableThColumn && this._tableThColumn.tagName === "TH") {
            this._diffX = e.pageX - this._pageX;
            this.template.querySelector("table").style.width =
                this.template.querySelector("table") - this._diffX + "px";

            this._tableThColumn.style.width = this._tableThWidth + this._diffX + "px";
            this._tableThInnerDiv.style.width = this._tableThColumn.style.width;

            let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
            let tableBodyRows = this.template.querySelectorAll("table tbody tr");
            tableBodyRows.forEach((row) => {
                let rowTds = row.querySelectorAll(".dv-dynamic-width");
                rowTds.forEach((td, ind) => {
                    rowTds[ind].style.width = tableThs[ind].style.width;
                });
            });
        }
    }

    handledblclickresizable() {
        let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
        let tableBodyRows = this.template.querySelectorAll("table tbody tr");
        tableThs.forEach((th, ind) => {
            th.style.width = this._initWidths[ind];
            th.querySelector(".slds-cell-fixed").style.width = this._initWidths[ind];
        });
        tableBodyRows.forEach((row) => {
            let rowTds = row.querySelectorAll(".dv-dynamic-width");
            rowTds.forEach((td, ind) => {
                rowTds[ind].style.width = this._initWidths[ind];
            });
        });
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
        retrieveTableView().then((data) => {
            if (data) {
                this.data = data.map((el) => {
                    let isElevate = el.recurringDonation.CommitmentId__c ? true : false;
                    let actions = this.actions
                        .filter((el) => {
                            if (el.name !== "updatePaymentMethod" && !isElevate) {
                                return el;
                            } else if (isElevate) {
                                return el;
                            }
                        })
                        .map((a) => {
                            return { ...a };
                        });
                    let nexDonationFormatFirstElement = "";
                    let nexDonationFormatSecondElement = "";
                    if (el.nextDonation) {
                        nexDonationFormatFirstElement = el.nextDonation.split(".")[0] || el.nextDonation;
                        nexDonationFormatSecondElement = el.nextDonation.split(".")[1] || "";
                    }
                    if (el.status === CANCELED_STATUS) {
                        actions.map((action) => {
                            action.disabled = true;
                            return action;
                        });
                    }
                    return { actions, ...el, nexDonationFormatFirstElement, nexDonationFormatSecondElement };
                });
            }
        });
    }
}
