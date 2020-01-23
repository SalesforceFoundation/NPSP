/* eslint-disable no-console */
import { LightningElement, api, track, wire } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import { deepClone } from 'c/utilCommon';
import retrieveOpportunities from '@salesforce/apex/FORM_ServiceGiftEntry.retrieveOpportunities';
import OPPORTUNITY_INFO from '@salesforce/schema/Opportunity';

import PAYMENT_INFO from '@salesforce/schema/npe01__OppPayment__c';

export default class geDonationMatching extends LightningElement {

    @api recordId;
    @api dedicatedListenerEventName;

    @track isLoading = true;

    opportunities;

    @wire(retrieveOpportunities, { recordId: '$recordId' })
    wiredRetrieveOpportunities(response) {
        if (response.data) {
            console.log('data: ', response.data);
            this.opportunities = response.data;
            this.isLoading = false;
        }

        if (response.error) {
            console.error(response.error);
        }
    }

    handleUpdateSelectedDonation(event) {
        console.log('handleUpdateSelectedDonation: ', deepClone(event.detail));

        if (event.detail.objectApiName === PAYMENT_INFO.objectApiName) {
            this.handlePayment(event.detail.fields);
        } else if (event.detail.objectApiName === OPPORTUNITY_INFO.objectApiName) {
            this.handleOpportunity(event.detail.fields);
        }
    }

    handlePayment(fields) {
        console.log('handlePayment');
        const detail = { receiverComponent: 'ge-batch-gift-entry-app', payment: fields };
        try {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, detail);
        } catch (error) {
            console.error(error);
        }
    }

    handleOpportunity(fields) {
        console.log('handleOpportunity');
        const detail = { receiverComponent: 'ge-batch-gift-entry-app', opportunity: fields };
        try {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, detail);
        } catch (error) {
            console.error(error);
        }
    }

    handleNewOpportunity() {
        console.log('updatePayment');
        const detail = { receiverComponent: 'ge-batch-gift-entry-app', opportunity: { new: true } };
        try {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, detail);
        } catch (error) {
            console.error(error);
        }
    }
}