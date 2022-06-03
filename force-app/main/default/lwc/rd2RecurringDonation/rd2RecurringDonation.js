import { LightningElement, api, wire, track } from 'lwc';
import commonAmount from '@salesforce/label/c.commonAmount';
import RDCL_Frequency from '@salesforce/label/c.RDCL_Frequency';
import lblStatus from '@salesforce/label/c.lblStatus';
import firstDonation from '@salesforce/label/c.firstDonation'
import nextDonation from '@salesforce/label/c.nextDonation';
import mostRecentDonation from '@salesforce/label/c.mostRecentDonation';
import lastModified from '@salesforce/label/c.lastModified';
import RD2_ViewMoreDetails from '@salesforce/label/c.RD2_ViewMoreDetails';
import RD2_ViewLessDetails from '@salesforce/label/c.RD2_ViewLessDetails';

import RECURRING_DONATION from '@salesforce/schema/npe03__Recurring_Donation__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import FORM_FACTOR from '@salesforce/client/formFactor';

const FormFactorType = Object.freeze({
    Large: 'Large',
    Medium: 'Medium',
    Small: 'Small',
});

const MOBILE_CLASSES_ROW = 'slds-truncate dv-dynamic-width dv-dynamic-mobile';
const DESKTOP_CLASSES_ROW = 'slds-truncate dv-dynamic-width';
const MOBILE_CLASSES_HEAD = 'slds-is-resizable dv-dynamic-width dv-dynamic-mobile';
const DESKTOP_CLASSES_HEAD = 'slds-is-resizable dv-dynamic-width';
export default class RecurringDonationTable extends LightningElement {
    @api
    donationTypeFilter = 'Show all Recurring Donations';
    
    @api 
    allowACHPaymentMethod;

    @track tdClasses = 'hide-td';

    formFactor = FORM_FACTOR;
    
    paymentMethod = '';

    fixedWidth = "width:8rem;";

    lastDonationDate = '';

    labels = {
      commonAmount,
      RDCL_Frequency,
      lblStatus,
      firstDonation,
      mostRecentDonation,
      nextDonation,
      lastModified,
      RD2_ViewMoreDetails,
      RD2_ViewLessDetails
    }

    data = [{
        "id": 1,
        "firstDonation": "7/4/2022",
        "donor": "Saba",
        "amount": 69,
        "paymentMethod": "Credit Card, *1111Exp. 11/2023",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecentDonation": "12/10/2023",
        "lastModified": "4/01/2023",
        "nextDonation": "<div class='slds-truncate dv-dynamic-width'>Paid Donation: 1 of 5.<br/> Next Donation: 1/12/2022.</div>"
      },
      {
        "id": 2,
        "firstDonation": "4/10/2022",
        "donor": "Siward",
        "amount": 43,
        "paymentMethod": "ACH, *1111",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecentDonation": "12/10/2023",
        "lastModified": "4/01/2023",
        "nextDonation": "<div class='slds-truncate dv-dynamic-width'>Paid Donation: 3 of 6.<br/> Next Donation: 12/20/2022.</div>"
      },
      {
        "id": 3,
        "firstDonation": "3/31/2022",
        "donor": "Page",
        "amount": 43,
        "paymentMethod": "Credit Card, *1111Exp. 11/2023",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecentDonation": "12/10/2023",
        "lastModified": "4/01/2023",
        "nextDonation": "<div class='slds-truncate dv-dynamic-width'>Paid Donation: 2 of 5.<br/> Next Donation: 2/22/2022.</div>"
      },
      {
        "id": 4,
        "firstDonation": "6/25/2022",
        "donor": "Eric",
        "amount": 91,
        "paymentMethod": "Check",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecentDonation": "12/10/2023",
        "lastModified": "4/01/2023",
        "nextDonation": "<div class='slds-truncate dv-dynamic-width'>Paid Donation: 2 of 10.<br/> Next Donation: 11/11/2022.</div>"
      },
      {
        "id": 5,
        "firstDonation": "5/18/2022",
        "donor": "Merrill",
        "amount": 10,
        "paymentMethod": "Credit Card",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecentDonation": "12/10/2023",
        "lastModified": "4/01/2023",
        "nextDonation": "<div class='slds-truncate dv-dynamic-width'>Paid Donation: 6 of 8.<br/> Next Donation: 12/22/2022.</div>"
    }];

    actions = [
      { label: 'View', name: 'view' },
      { label: 'Delete', name: 'delete' }
    ];

    columns = [];
    
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION })
    oppInfo({ data, error }) {
        if (data){
          this.paymentMethod = data.fields.PaymentMethod__c.label;
        }
    }

    connectedCallback() {
      if(!this.isMobile){
        this.tdClasses = '';
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
     * @description Returns the classes to be applied to the rows accordling if it is mobile or desktop
     */
    get rowClasses() {
      if (this.isMobile) {
          return MOBILE_CLASSES_ROW;
      }
      return DESKTOP_CLASSES_ROW;
    }

    /**
     * @description Returns the classes to be applied to the headers accordling if it is mobile or desktop
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
            this._tableViewInnerDiv.style = 'width:' + (event.currentTarget.scrollLeft + this._tableViewInnerDivOffsetWidth) + "px;" + this.tableBodyStyle;
        }
        this.tableScrolled(event);
    }
 
    tableScrolled(event) {
        if (this.enableInfiniteScrolling) {
            if ((event.target.scrollTop + event.target.offsetHeight) >= event.target.scrollHeight) {
                this.dispatchEvent(new CustomEvent('showmorerecords', {
                    bubbles: true
                }));
            }
        }
        if (this.enableBatchLoading) {
            if ((event.target.scrollTop + event.target.offsetHeight) >= event.target.scrollHeight) {
                this.dispatchEvent(new CustomEvent('shownextbatch', {
                    bubbles: true
                }));
            }
        }
    }
 
    //#region ***************** RESIZABLE COLUMNS *************************************/
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
            tableThs.forEach(th => {
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
 
            this.template.querySelector("table").style.width = (this.template.querySelector("table") - (this._diffX)) + 'px';
 
            this._tableThColumn.style.width = (this._tableThWidth + this._diffX) + 'px';
            this._tableThInnerDiv.style.width = this._tableThColumn.style.width;
 
            let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
            let tableBodyRows = this.template.querySelectorAll("table tbody tr");
            tableBodyRows.forEach(row => {
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
        tableBodyRows.forEach(row => {
            let rowTds = row.querySelectorAll(".dv-dynamic-width");
            rowTds.forEach((td, ind) => {
                rowTds[ind].style.width = this._initWidths[ind];
            });
        });
    }
 
    paddingDiff(col) {
 
        if (this.getStyleVal(col, 'box-sizing') === 'border-box') {
            return 0;
        }
 
        this._padLeft = this.getStyleVal(col, 'padding-left');
        this._padRight = this.getStyleVal(col, 'padding-right');
        return (parseInt(this._padLeft, 10) + parseInt(this._padRight, 10));
 
    }
 
    getStyleVal(elm, css) {
        return (window.getComputedStyle(elm, null).getPropertyValue(css))
    }
   
    hideAndShow( event ) {
      let tableTd= this.template.querySelectorAll("td[data-id="+JSON.stringify(event.target.getAttribute("data-viewid"))+"]");
      let viewMoreOrLess = this.template.querySelector("td[data-viewid="+JSON.stringify(event.target.getAttribute("data-viewid"))+"]");
      if(viewMoreOrLess.getAttribute("data-label") === this.labels.RD2_ViewMoreDetails){
        viewMoreOrLess.setAttribute("data-label", this.labels.RD2_ViewLessDetails) 
      } else{ 
        viewMoreOrLess.setAttribute("data-label", this.labels.RD2_ViewMoreDetails)
      }
      tableTd.forEach(td => {
        if(td.classList.contains('hide-td')){
          td.classList.remove('hide-td');
        } else {
          td.classList.add('hide-td');
        }
      });
    }
}