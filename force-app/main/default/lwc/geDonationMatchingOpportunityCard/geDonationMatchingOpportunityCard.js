import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { handleError } from 'c/utilTemplateBuilder';
import { deepClone } from 'c/utilCommon';
import geLabelService from 'c/geLabelService';

import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import OPPORTUNITY_NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import OPPORTUNITY_AMOUNT_FIELD from '@salesforce/schema/Opportunity.Amount';
import OPPORTUNITY_CLOSE_DATE_FIELD from '@salesforce/schema/Opportunity.CloseDate';
import OPPORTUNITY_STAGE_NAME_FIELD from '@salesforce/schema/Opportunity.StageName';

const FIELDS = [
    OPPORTUNITY_NAME_FIELD,
    OPPORTUNITY_AMOUNT_FIELD,
    OPPORTUNITY_CLOSE_DATE_FIELD,
    OPPORTUNITY_STAGE_NAME_FIELD,
]

export default class geDonationMatchingOpportunityCard extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = geLabelService.CUSTOM_LABELS;

    @api opportunityWrapper;
    @api selectedDonationId;

    @track opportunityObject;
    @track wiredOpportunityRecord;

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    wiredOpportunityObject(response) {
        if (response.data) {
            this.opportunityObject = response.data;
        }

        if (response.error) {
            handleError(response.error);
        }
    }

    @wire(getRecord, { recordId: '$opportunityId', fields: FIELDS })
    wiredOpportunity(response) {
        if (response.data) {
            this.wiredOpportunityRecord = response.data;
        }

        if (response.error) {
            handleError(response.error);
        }
    }

    get isLoading() {
        return this.opportunityObject && this.wiredOpportunityRecord ? false : true;
    }

    get opportunity() {
        return this.opportunityWrapper.opportunity;
    }

    get opportunityId() {
        return this.opportunity.Id;
    }

    get opportunityComputedName() {
        if (this.wiredOpportunityRecord) {
            return geLabelService.format(this.CUSTOM_LABELS.geHeaderMatchingOpportunity,
                [
                    this.opportunityAmountDetails.value,
                    this.opportunityCloseDateDetails.value,
                    this.opportunityStageNameDetails.value
                ]);
        }
        return '';
    }

    get isUpdateOpportunityDisabled() {
        return this.opportunity && this.opportunityPayments.length === 1 ? true : false;
    }

    get opportunityObjectApiName() {
        return OPPORTUNITY_OBJECT.objectApiName ? OPPORTUNITY_OBJECT.objectApiName : undefined;
    }

    get opportunityAmountDetails() {
        return this.getFieldDetails(OPPORTUNITY_AMOUNT_FIELD, this.wiredOpportunityRecord);
    }

    get opportunityCloseDateDetails() {
        return this.getFieldDetails(OPPORTUNITY_CLOSE_DATE_FIELD, this.wiredOpportunityRecord);
    }

    get opportunityStageNameDetails() {
        return this.getFieldDetails(OPPORTUNITY_STAGE_NAME_FIELD, this.wiredOpportunityRecord);
    }

    get opportunityNameDetails() {
        return this.getFieldDetails(OPPORTUNITY_NAME_FIELD, this.wiredOpportunityRecord);
    }

    get hasPayments() {
        return this.opportunityWrapper.unpaidPayments &&
            this.opportunityWrapper.unpaidPayments.length > 0;
    }

    get opportunityPayments() {
        return this.hasPayments ? this.opportunityWrapper.unpaidPayments : [];
    }

    get isSelectedDonation() {
        return this.selectedDonationId &&
            this.opportunity &&
            this.opportunity.Id === this.selectedDonationId ?
            true :
            false;
    }

    get computedCardCssClass() {
        return this.isSelectedDonation ? 'slds-card_extension_active' : '';
    }

    getFieldDetails(fieldInfo, wiredOpportunityRecord) {
        const fieldApiName = fieldInfo.fieldApiName;
        const fields = this.opportunityObject.fields;
        if (fields && wiredOpportunityRecord) {
            const value =
                wiredOpportunityRecord.fields[fieldApiName].displayValue ||
                wiredOpportunityRecord.fields[fieldApiName].value ||
                '';

            return {
                label: `${this.opportunityObject.label} ${fields[fieldApiName].label}`,
                fieldApiName: fieldApiName,
                value: value,
            };
        }
        return { fieldApiName: fieldApiName };
    }

    /*******************************************************************************
    * @description Method dispatches an event to notify geDonationMatching that a
    * payment donation has been selected.
    *
    * @param {object} event: Custom Event object containing payment data.
    */
    handleUpdatePayment(event) {
        this.dispatchEvent(new CustomEvent('updateselecteddonation', {
            detail: {
                ...event.detail,
                softCredits: this.retrieveSoftCredits()
            }
        }));
    }

    /*******************************************************************************
    * @description Method dispatches an event to notify geDonationMatching that an
    * opportunity donation has been selected.
    *
    * @param {object} event: Custom Event object containing opportunity data.
    */
    handleUpdateOpportunity() {
        const detail = {
            objectApiName: OPPORTUNITY_OBJECT.objectApiName,
            fields: deepClone(this.opportunity),
            softCredits: this.retrieveSoftCredits()
        };
        this.dispatchEvent(new CustomEvent('updateselecteddonation', { detail }));
    }

    /*******************************************************************************
    * @description Method dispatches an event to notify geDonationMatching that a
    * new payment needs to be applied to the designated opportunity.
    *
    * @param {object} event: Custom Event object containing opportunity data.
    */
    handleNewPayment() {
        const detail = {
            objectApiName: OPPORTUNITY_OBJECT.objectApiName,
            fields: deepClone(this.opportunity),
            softCredits: this.retrieveSoftCredits()
        };
        detail.fields.applyPayment = true;
        this.dispatchEvent(new CustomEvent('updateselecteddonation', { detail }));
    }

    retrieveSoftCredits() {
        let softCredits = [];
        if (this.opportunityWrapper?.softCredits?.all) {
            softCredits = [ ...this.opportunityWrapper.softCredits.all ];
        }
        return softCredits;
    }

    // ================================================================================
    // AUTOMATION LOCATOR GETTERS
    // ================================================================================

    get qaLocatorAddNewPayment() {
        return `button ${this.CUSTOM_LABELS.geButtonMatchingNewPayment} ${this.opportunityNameDetails.value}`;
    }

    get qaLocatorUpdateOpportunity() {
        return `button ${this.CUSTOM_LABELS.geButtonMatchingUpdateOpportunity} ${this.opportunityNameDetails.value}`;
    }
}