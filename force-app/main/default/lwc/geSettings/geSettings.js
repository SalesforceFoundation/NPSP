import isElevateCustomer from "@salesforce/apex/GE_GiftEntryController.isElevateCustomer";

class GeSettings {
    _isElevateCustomer = undefined;

    async init() {
        this._isElevateCustomer = await isElevateCustomer();
    }

    isElevateCustomer() {
        return this._isElevateCustomer;
    };
}

const geSettings = new GeSettings();

export default geSettings;