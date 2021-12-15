import { LightningElement, api, track } from "lwc";

export default class RelationshipsNavigator extends LightningElement {
    @api recordId;

    @track contactIds = [];

    handleLoadRelations(event) {
        const contactId = event.detail;

        if (this.isAlreadyLoaded(contactId)) {
            this.focusTableWithId(contactId);
        } else {
            this.contactIds.push(contactId);
        }
    }

    isAlreadyLoaded(contactId) {
        return this.contactIds.includes(contactId) || this.recordId === contactId;
    }

    handleTableLoaded(event) {
        event.target.focus();
        event.target.scrollIntoView();
    }

    focusTableWithId(contactId) {
        const element = this.template.querySelector(`c-relationships-table[data-contact-id='${contactId}']`);
        element.focus();
        element.scrollIntoView();
    }
}