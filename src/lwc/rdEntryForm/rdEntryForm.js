import { LightningElement, api } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';

import commonCancel from '@salesforce/label/c.commonCancel';
import commonSave from '@salesforce/label/c.commonSave';

export default class rdEntryForm extends LightningElement {
    CUSTOM_LABELS = Object.freeze({
        commonCancel,
        commonSave
    });

    @api parentId;
    @api recordId;
    contactId;
    accountId;

    listenerEvent = 'rdEntryFormEvent';

   connectedCallback() {
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the cancel action if
    * a dedicated listener event name is provided otherwise dispatches a CustomEvent.
    */
   handleCancel() {
        fireEvent(this.pageRef, 'rdEntryFormEvent', { action: 'cancel' });
    }
}