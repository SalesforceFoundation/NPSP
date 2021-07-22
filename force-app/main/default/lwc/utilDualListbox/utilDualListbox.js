import { LightningElement, api } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';

import commonCancel from '@salesforce/label/c.commonCancel';
import commonSave from '@salesforce/label/c.commonSave';

export default class utilDualListbox extends LightningElement {

    CUSTOM_LABELS = Object.freeze({
        commonCancel,
        commonSave
    });

    @api cssClass;
    @api name;
    @api label;
    @api sourceLabel;
    @api selectedLabel;
    @api options = [];
    @api values = [];
    @api requiredOptions = [];
    @api min;
    @api max;
    @api showModalFooter = false;
    @api dedicatedListenerEventName;
    @api targetComponentName;

    @api
    set header(value) {
        this.hasHeaderString = value !== '';
        this._headerPrivate = value;
    }
    get header() {
        return this._headerPrivate;
    }

    hasHeaderString = false;
    _headerPrivate;

    handleChange = (event) => {
        this.values = event.detail.value;
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the save action if
    * a dedicated listener event name is provided otherwise dispatches a CustomEvent.
    */
    handleSave() {
        const payload = { values: this.values, name: this.name };
        const detail = { receiverComponent: this.targetComponentName, action: 'save', payload: payload };
        if (this.dedicatedListenerEventName) {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, detail);
        } else {
            this.dispatchEvent(new CustomEvent('save', { detail: payload }));
        }
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the cancel action if
    * a dedicated listener event name is provided otherwise dispatches a CustomEvent.
    */
    handleCancel() {
        if (this.dedicatedListenerEventName) {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, { action: 'cancel' });
        } else {
            this.dispatchEvent(new CustomEvent('cancel', { detail: {} }));
        }
    }


    /*******************************************************************************
     * Start getters for data-qa-locator attributes
     */

    get qaLocatorCancel() {
        return 'button Listbox Cancel';
    }

    get qaLocatorSave() {
        return 'button Listbox Save'
    }

    /*******************************************************************************
     * End getters for data-qa-locator attributes
     */
}