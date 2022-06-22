import isElevateCustomer from "@salesforce/apex/GE_GiftEntryController.isElevateCustomer";
import isRecurringGiftsEnabled from "@salesforce/apex/GE_GiftEntryController.isRecurringGiftsEnabled";
import canMakeGiftsRecurring from "@salesforce/apex/GE_GiftEntryController.canMakeGiftsRecurring";

class GeSettings {
    _isElevateCustomer = undefined;
    _isRecurringGiftsEnabled = false;
    _canMakeGiftsRecurring = false;

    async init() {
        this._isElevateCustomer = await isElevateCustomer();
        this._isRecurringGiftsEnabled = await isRecurringGiftsEnabled();
        this._canMakeGiftsRecurring = await canMakeGiftsRecurring();
    }

    isElevateCustomer() {
        return this._isElevateCustomer;
    };

    canMakeGiftsRecurring() {
        return this._isRecurringGiftsEnabled && this._canMakeGiftsRecurring;
    }
}

const geSettings = new GeSettings();

export default geSettings;