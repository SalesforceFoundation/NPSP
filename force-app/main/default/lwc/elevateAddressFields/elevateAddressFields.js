import { api, LightningElement, track} from 'lwc';
import { debouncify } from 'c/utilCommon';
import retrieveDonorAddress from '@salesforce/apex/GE_GiftEntryController.retrieveDonorAddress';
import { handleError } from 'c/utilTemplateBuilder';
import { fireEvent } from 'c/pubsubNoPageRef';

export default class ElevateAddressFields extends LightningElement {

    _showBillingAddressFields = false;
    _donorAddress;

    @api selectedDonorId;


    @track addressFields = {
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
        this.addressFields = {};
        this._showBillingAddressFields = false;
    }

    handleValueChangeSync = (event) => {
        const allInputs = this.template.querySelectorAll('lightning-input')
        allInputs.forEach(element => {
            this.addressFields[element.name] = element.value;
        })
    };
    handleOnChange = debouncify(this.handleValueChangeSync.bind(this), 300);

    handleClearAddress() {
        this.addressFields = {};
    }

    async handleUseDonorAddress() {
        if (!this.selectedDonorId.donorId) {
            this.dispatchApplicationEvent('displayWidgetError', {
                error: 'Please provide an address for this donor'
            });
            return;
        }
        try {
            const retrievedAddress = await retrieveDonorAddress(
                { donorId: this.selectedDonorId.donorId }
            );
            this.addressFields = Object.assign({}, retrievedAddress);
        } catch (err) {
            handleError(err);
        }
    }

    @api
    get addressFields() {
       return this.addressFields;
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