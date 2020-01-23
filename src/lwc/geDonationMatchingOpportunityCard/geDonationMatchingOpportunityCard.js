import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { dispatch, handleError } from 'c/utilTemplateBuilder';
import { deepClone } from 'c/utilCommon';

import OPPORTUNITY_INFO from '@salesforce/schema/Opportunity';
import OPPORTUNITY_NAME_INFO from '@salesforce/schema/Opportunity.Name';
import OPPORTUNITY_AMOUNT_INFO from '@salesforce/schema/Opportunity.Amount';
import OPPORTUNITY_CLOSE_DATE_INFO from '@salesforce/schema/Opportunity.CloseDate';
import OPPORTUNITY_STAGE_NAME_INFO from '@salesforce/schema/Opportunity.StageName';

export default class geDonationMatchingOpportunityCard extends LightningElement {

    @api opportunity;

    @track isLoading = true;

    opportunityObject;

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_INFO })
    wiredOpportunityObject(response) {
        if (response.data) {
            this.opportunityObject = response.data;
            this.isLoading = false;
        }

        if (response.error) {
            handleError(response.error);
        }
    }

    get opportunityAmountDetails() {
        return this.getFieldDetails(OPPORTUNITY_AMOUNT_INFO);
    }

    get opportunityCloseDateDetails() {
        return this.getFieldDetails(OPPORTUNITY_CLOSE_DATE_INFO);
    }

    get opportunityStageNameDetails() {
        return this.getFieldDetails(OPPORTUNITY_STAGE_NAME_INFO);
    }

    get opportunityNameDetails() {
        return this.getFieldDetails(OPPORTUNITY_NAME_INFO);
    }

    get hasPayments() {
        return this.opportunity &&
            this.opportunity.npe01__OppPayment__r &&
            this.opportunity.npe01__OppPayment__r.length > 0;
    }

    get opportunityPayments() {
        return this.hasPayments ? this.opportunity.npe01__OppPayment__r : [];
    }

    getFieldDetails(fieldInfo) {
        const fieldApiName = fieldInfo.fieldApiName;
        const fields = this.opportunityObject.fields;
        if (fields) {
            // TODO: Use custom label for opportunity
            return { label: `Opportunity ${fields[fieldApiName].label}`, value: this.opportunity[fieldApiName] };
        }
        return null;
    }

    handleUpdatePayment(event) {
        console.log('handleUpdatePayment: ', deepClone(event.detail));
        dispatch(this, 'updateselecteddonation', event.detail);
    }

    handleUpdateOpportunity() {
        console.log('handleUpdateOpportunity: ', deepClone(this.opportunity), OPPORTUNITY_INFO);
        const detail = { objectApiName: OPPORTUNITY_INFO.objectApiName, fields: deepClone(this.opportunity) };
        dispatch(this, 'updateselecteddonation', detail);
    }

    handleNewPayment() {
        console.log('handleUpdateOpportunity: ', deepClone(this.opportunity), OPPORTUNITY_INFO);
        const detail = { objectApiName: OPPORTUNITY_INFO.objectApiName, fields: deepClone(this.opportunity) };
        detail.fields.applyPayment = true;
        dispatch(this, 'updateselecteddonation', detail);
    }
}