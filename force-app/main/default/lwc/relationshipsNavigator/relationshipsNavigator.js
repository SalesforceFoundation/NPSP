import { LightningElement, api, track } from "lwc";

export default class RelationshipsNavigator extends LightningElement {
    @api recordId;

    @track contactIds = [];

    handleLoadRelations(event) {
        const contactId = event.detail;

        if (this.contactIds.includes(contactId)) {
            this.focusTableWithId(contactId);
        } else {
            this.contactIds.push(contactId);
        }
    }

    handleTableLoaded(event) {
        event.target.focus();
    }

    focusTableWithId(contactId) {
        this.template.querySelector(`c-relationships-table[data-contact-id='${contactId}']`).focus();
    }
}