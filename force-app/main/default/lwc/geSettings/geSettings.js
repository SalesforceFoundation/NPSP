import isElevateCustomer from "@salesforce/apex/GE_GiftEntryController.isElevateCustomer";
import canAccessRecurringDonationFields from "@salesforce/apex/GE_GiftEntryController.canAccessRecurringDonationFields";

class GeSettings {
    _isElevateCustomer = undefined;
    _canAccessRecurringDonationFields = false;

    async init() {
        this._isElevateCustomer = await isElevateCustomer();
        this._canAccessRecurringDonationFields = await canAccessRecurringDonationFields();
    }

    isElevateCustomer() {
        return this._isElevateCustomer;
    };

    canAccessRecurringDonationFields() {
        return this._canAccessRecurringDonationFields;
    }
}

const geSettings = new GeSettings();

export default geSettings;