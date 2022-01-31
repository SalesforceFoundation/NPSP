import isElevateCustomer from "@salesforce/apex/GE_GiftEntryController.isElevateCustomer";
import isRecurringGiftsEnabled from "@salesforce/apex/GE_GiftEntryController.isRecurringGiftsEnabled";

class GeSettings {
    _isElevateCustomer = undefined;
    _isRecurringGiftsEnabled = undefined;

    async init() {
        this._isElevateCustomer = await isElevateCustomer();
        this._isRecurringGiftsEnabled = await isRecurringGiftsEnabled();
    }

    isElevateCustomer() {
        return this._isElevateCustomer;
    };

    isRecurringGiftsEnabled() {
        return this._isRecurringGiftsEnabled;
    }
}

const geSettings = new GeSettings();

export default geSettings;