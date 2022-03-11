import { api, LightningElement, track } from 'lwc';
import donationHistoryLabelLifetime from '@salesforce/label/c.donationHistoryLabelLifetime';
import donationHistoryFilterSelectAYear from '@salesforce/label/c.donationHistoryFilterSelectAYear';
import getYearsWithDonation from '@salesforce/apex/DonationHistoryController.getYearsWithDonations';
import getContactIdByUserId from "@salesforce/apex/DonationHistoryController.getContactIdByUserId";

const LIFETIME_VALUE = 'lifetime';
export default class DonationHistoryFilter extends LightningElement {
    
    @api contactId;

    @track options = [];

    labels = {
        lifetime : donationHistoryLabelLifetime,
        donationHistoryFilterSelectAYear : donationHistoryFilterSelectAYear
    }

    value = LIFETIME_VALUE;
    
    connectedCallback() {
        this.getYearsWithDonationsByContact();
    }

    getYearsWithDonationsByContact(){
    getYearsWithDonation({contactId : this.contactId})
        .then(
            result => {
                this.options = this.generateOptionsFromYearsList(this.generateYearList(result));
            }).catch(error => {
                console.info(error);
            });
    }

    /**
     * From a list of years, it generates the options for the combobox array(with Lifetime element).
     * @param {[string]} yearList 
     * @returns List of options the years with Lifetime element
     */
    generateOptionsFromYearsList(yearList) {
        let toReturn = [{label: this.labels.lifetime, value: LIFETIME_VALUE}];
        yearList.forEach( (year) => {
            toReturn.push({label: '' + year, value: '' + year});
        });
        return toReturn;
    } 

    /**
     * Returns all the years between the first year of the array and the last year
     * @param {[string]} yearList 
     * @returns Returns all the years between the first year of the array and the last year
     */
    generateYearList(yearList) {
        let toReturn = [];
        for (let i = yearList[0]; i >= yearList[yearList.length - 1]; i--) {
            toReturn.push(i);
        }
        return toReturn;

    }
    
    handleChange(e) {
        this.value = e.detail.value;
        this.dispatchEvent(new CustomEvent('filter', {detail: this.value}));
    }

}