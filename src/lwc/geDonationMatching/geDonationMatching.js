/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import { handleError } from 'c/utilTemplateBuilder';
import geLabelService from 'c/geLabelService';

import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import PAYMENT_OBJECT from '@salesforce/schema/npe01__OppPayment__c';

export default class geDonationMatching extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = geLabelService.CUSTOM_LABELS;

    @api opportunities;
    @api dedicatedListenerEventName;
    @api receiverComponent;

    @track isLoading = true;

    renderedCallback() {
        if (this.isLoading) {
            this.isLoading = false;
        }
    }

    handleUpdateSelectedDonation(event) {
        if (event.detail.objectApiName === PAYMENT_OBJECT.objectApiName) {
            this.handlePayment(event.detail.fields);
        } else if (event.detail.objectApiName === OPPORTUNITY_OBJECT.objectApiName) {
            this.handleOpportunity(event.detail.fields);
        }
    }

    handlePayment(fields) {
        const detail = { receiverComponent: this.receiverComponent, payment: fields };
        fireEvent(this.pageRef, this.dedicatedListenerEventName, detail);
    }

    handleOpportunity(fields) {
        const detail = { receiverComponent: this.receiverComponent, opportunity: fields };
        fireEvent(this.pageRef, this.dedicatedListenerEventName, detail);
    }

    handleNewOpportunity() {
        const detail = { receiverComponent: this.receiverComponent, opportunity: { new: true } };
        fireEvent(this.pageRef, this.dedicatedListenerEventName, detail);
    }
}