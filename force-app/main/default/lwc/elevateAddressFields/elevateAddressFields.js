import { api, LightningElement, track} from 'lwc';
import { debouncify } from 'c/utilCommon';
import retrieveDonorAddress from '@salesforce/apex/GE_GiftEntryController.retrieveDonorAddress';
import { handleError } from 'c/utilTemplateBuilder';
import { fireEvent } from 'c/pubsubNoPageRef';
import billingAddressLabel from "@salesforce/label/c.elevateBillingAddress";
import billingCityLabel from "@salesforce/label/c.lblCity";
import billingPostalCodeLabel from "@salesforce/label/c.lblPostalCode";
import billingStateLabel from "@salesforce/label/c.lblState";
import billingStreetLabel from "@salesforce/label/c.lblStreet";
import billingCountryLabel from "@salesforce/label/c.lblCountry";
import billingAddressHelpLabel from "@salesforce/label/c.elevateBillingAddressHelp";
import donorAddressEmptyLabel from "@salesforce/label/c.elevateDonorAddressEmpty";
import clearAddressLabel from "@salesforce/label/c.elevateClearAddress";
import useDonorAddressLabel from "@salesforce/label/c.elevateUseDonorAddress";
import addBillingAddressButtonLabel from "@salesforce/label/c.elevateAddBillingAddress";
import removeBillingAddressButtonLabel from "@salesforce/label/c.elevateRemoveBillingAddress";

export default class ElevateAddressFields extends LightningElement {

    labels = {
        billingAddressLabel,
        billingCityLabel,
        billingPostalCodeLabel,
        billingStateLabel,
        billingStreetLabel,
        billingCountryLabel,
        billingAddressHelpLabel,
        clearAddressLabel,
        donorAddressEmptyLabel,
        useDonorAddressLabel,
        addBillingAddressButtonLabel,
        removeBillingAddressButtonLabel,
    };


    _showBillingAddressFields = false;
    _donorAddress;

    billingStreetLabel1 = billingStreetLabel + " 1";
    billingStreetLabel2 = billingStreetLabel + " 2";

    @api selectedDonorId;


    @track _addressFields = {
        city: '',
        country: '',
        addressLine1: '',
        addressLine2: '',
        postalCode: '',
        state: '',
    };

    get showBillingAddressFields() {
        return this._showBillingAddressFields;
    }

    handleShowBillingAddressFields() {
        this._showBillingAddressFields = true;
    }

    handleRemoveBillingAddressFields() {
        this._addressFields = {};
        this._showBillingAddressFields = false;
    }

    handleValueChangeSync = () => {
        const allInputs = this.template.querySelectorAll('lightning-input')
        allInputs.forEach(element => {
            this.addressFields[element.name] = element.value;
        })
    };
    handleOnChange = debouncify(this.handleValueChangeSync.bind(this), 300);

    handleClearAddress() {
        this._addressFields = {};
    }

    async handleUseDonorAddress() {
        if (!this.selectedDonorId.donorId) {
            this.dispatchApplicationEvent('displayWidgetError', {
                error: this.labels.donorAddressEmptyLabel
            });
            return;
        }
        try {
            const retrievedAddress = await retrieveDonorAddress(
                { donorId: this.selectedDonorId.donorId }
            );
            this._addressFields = Object.assign({}, retrievedAddress);
        } catch (err) {
            handleError(err);
        }
    }

    @api
    get addressFields() {
       return this._addressFields;
    }

    dispatchApplicationEvent(eventName, payload) {
        fireEvent(null, eventName, payload);
    }

    get qaLocatorAddBillingAddress() {
        return `button Add Billing Address`;
    }

    get qaLocatorRemoveBillingAddress() {
        return `button Remove Billing Address`;
    }

    get qaLocatorUseDonorAddress() {
        return `button Use Donor Address`;
    }

    get qaLocatorClearAddress() {
        return `button Clear Address`;
    }

    get qaLocatorStreet1() {
        return `input Street 1`;
    }

    get qaLocatorStreet2() {
        return `input Street 2`;
    }

    get qaLocatorCity() {
        return `input City`;
    }

    get qaLocatorState() {
        return `input State`;
    }

    get qaLocatorPostalCode() {
        return `input Postal Code`;
    }

    get qaLocatorCountry() {
        return `input Country`;
    }
}