/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import geLabelService from 'c/geLabelService';

import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import PAYMENT_OBJECT from '@salesforce/schema/npe01__OppPayment__c';

export default class geDonationMatching extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = geLabelService.CUSTOM_LABELS;

    @api opportunities;
    @api dedicatedListenerEventName;
    @api receiverComponent;
    @api selectedDonationId;

    @track isLoading = true;

    renderedCallback() {
        if (this.isLoading) {
            this.isLoading = false;
        }
    }

    /*******************************************************************************
    * @description Method receives an event from the child component
    * geDonationMatchingOpportunityCard with data for the selected donation.
    *
    * @param {object} event: Custom Event object received from child component
    * containing data for the selected donation (Opportunity or Payment).
    */
    handleUpdateSelectedDonation(event) {
        if (event.detail.objectApiName === PAYMENT_OBJECT.objectApiName) {
            this.handlePayment(event.detail);
        } else if (event.detail.objectApiName === OPPORTUNITY_OBJECT.objectApiName) {
            this.handleOpportunity(event.detail);
        }
    }

    /*******************************************************************************
    * @description Method handles events from a payment donation selection and
    * dispatches another event to be handled by geFormRenderer and/or another
    * component that listening to pubsub channel this.dedicatedListenerEventName.
    */
    handlePayment(fields) {
        const detail = { receiverComponent: this.receiverComponent, payment: fields };
        fireEvent(this.pageRef, this.dedicatedListenerEventName, { detail });
    }

    /*******************************************************************************
    * @description Method handles events from a opportunity donation selection and
    * dispatches another event to be handled by geFormRenderer and/or another
    * component that listening to pubsub channel this.dedicatedListenerEventName.
    */
    handleOpportunity(fields) {
        const detail = { receiverComponent: this.receiverComponent, opportunity: fields };
        fireEvent(this.pageRef, this.dedicatedListenerEventName, { detail });
    }

    /*******************************************************************************
    * @description Method handles events from a new opportunity donation selection and
    * dispatches another event to be handled by geFormRenderer and/or another
    * component that listening to pubsub channel this.dedicatedListenerEventName.
    */
    handleNewOpportunity() {
        const detail = {
            receiverComponent: this.receiverComponent,
            opportunity: {
                new: true,
                attributes: {type: OPPORTUNITY_OBJECT.objectApiName}
            }
        };
        fireEvent(this.pageRef, this.dedicatedListenerEventName, { detail });
    }

    // ================================================================================
    // AUTOMATION LOCATOR GETTERS
    // ================================================================================

    get qaLocatorNewOpportunity() {
        return `button ${this.CUSTOM_LABELS.geButtonMatchingNewOpportunity}`;
    }
}