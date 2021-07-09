import {LightningElement, api, wire} from 'lwc';
import GeLabelService from 'c/geLabelService';
import {
    apiNameFor,
    isEmpty,
    isNumeric
} from 'c/utilCommon';

import OPP_CONTACT_ROLE_OBJECT from '@salesforce/schema/OpportunityContactRole';
import ROLE_FIELD from '@salesforce/schema/OpportunityContactRole.Role';
import CONTACT_FIELD from '@salesforce/schema/OpportunityContactRole.ContactId';
import OPPORTUNITY_FIELD from '@salesforce/schema/OpportunityContactRole.OpportunityId';

export default class GeFormWidgetRowAllocation extends LightningElement {
    @api rowIndex;
    @api row;
    @api fieldList;
    @api disabled;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    handleFieldValueChange = (event) => {
        // do stuff
    }

    remove() {
        const { rowIndex, row } = this;
        this.dispatchEvent(new CustomEvent('remove', { detail: { rowIndex, row } }));
    }

    get isRemovable() {
        return this.disabled !== true;
    }

    get softCreditObjectApiName() {
        return apiNameFor(OPP_CONTACT_ROLE_OBJECT);
    }

    get roleFieldApiName() {
        return apiNameFor(ROLE_FIELD);
    }

    get roleValue() {
        return this.row.record[apiNameFor(ROLE_FIELD)];
    }

    get contactFieldApiName() {
        return apiNameFor(CONTACT_FIELD);
    }
    get contactValue() {
        return this.row.record[apiNameFor(CONTACT_FIELD)];
    }
    
}