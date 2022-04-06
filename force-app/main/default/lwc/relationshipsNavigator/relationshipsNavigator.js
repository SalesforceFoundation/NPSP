import { LightningElement, api, wire } from "lwc";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import CONTACT_NAME from "@salesforce/schema/Contact.Name";
import accessDeniedMessage from "@salesforce/label/c.addrCopyConAddBtnFls";
import insufficientPermissions from "@salesforce/label/c.commonInsufficientPermissions";

export default class RelationshipsNavigator extends LightningElement {
    @api recordId;

    @api
    set isLightningOut(val) {
        this._isLightningOut = val;
    }

    get isLightningOut() {
        return this._isLightningOut;
    }
    _isLightningOut;

    labels = {
        accessDeniedMessage,
        insufficientPermissions,
    };

    @wire(getRecord, { recordId: "$recordId", fields: [CONTACT_NAME] })
    contact;

    error;

    handleAccessError(event) {
        this.error = event.detail;
    }

    get contactName() {
        if (this.contact.data) {
            return getFieldValue(this.contact.data, CONTACT_NAME);
        }
    }
}
