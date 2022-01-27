import isElevateCustomer from "@salesforce/apex/GE_GiftEntryController.isElevateCustomer";
// TODO: Implement and import a call to retrieve the value of _isRecurringGiftsEnabled

class GeSettings {
    _isElevateCustomer = undefined;
    _isRecurringGiftsEnabled = true;

    async init() {
        this._isElevateCustomer = await isElevateCustomer();
    }

    isElevateCustomer() {
        return this._isElevateCustomer;
    };

    isRecurringGiftsEnabled() {
        // TODO: replace placeholder with actual value
        return this._isRecurringGiftsEnabled;
    }
}

const geSettings = new GeSettings();

export default geSettings;