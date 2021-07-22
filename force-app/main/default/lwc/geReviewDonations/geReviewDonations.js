import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { handleError } from 'c/utilTemplateBuilder';
import { registerListener, unregisterListener } from 'c/pubsubNoPageRef';
import geLabelService from 'c/geLabelService';
import getOpenDonations from '@salesforce/apex/GE_GiftEntryController.getOpenDonations';
import OPPORTUNITY from '@salesforce/schema/Opportunity';
import PAYMENT from '@salesforce/schema/npe01__OppPayment__c';
import { hasNestedProperty } from 'c/utilCommon';

export default class geReviewDonations extends NavigationMixin(LightningElement) {

    CUSTOM_LABELS = geLabelService.CUSTOM_LABELS;

    @api donorId;

    _donor;
    _donorType;
    _donationType;
    _selectedDonation;
    _opportunities = [];
    _dedicatedListenerEventName = 'geModalCloseEvent';

    connectedCallback() {
        registerListener('resetReviewDonationsEvent', this.handleResetReviewDonationsComponent, this);
    }

    disconnectedCallback() {
        unregisterListener('resetReviewDonationsEvent', this.handleResetReviewDonationsComponent, this);
    }

    @wire(getRecord, { recordId: '$donorId', optionalFields: ['Account.Name', 'Contact.Name'] })
    wiredGetRecord({ error, data }) {
        if (error) return handleError(error);
        if (data) {
            this._donor = data;
            this._donorType = this._donor.apiName;
        }
    }

    @wire(getOpenDonations, { donorId: '$donorId', donorType: '$_donorType' })
    wiredGetOpenDonations({ error, data }) {
        if (error) return handleError(error);
        if (data) return this.opportunities = JSON.parse(data);
    }

    @api
    get selectedDonation() {
        return this._selectedDonation;
    }

    set selectedDonation(donation) {
        this._selectedDonation = donation;

        const hasNestedTypeProperty = hasNestedProperty(donation, 'attributes', 'type');
        if (hasNestedTypeProperty && donation.attributes.type === PAYMENT.objectApiName) {
            this._donationType = PAYMENT.objectApiName;
        } else if (hasNestedTypeProperty && donation.attributes.type === OPPORTUNITY.objectApiName) {
            this._donationType = OPPORTUNITY.objectApiName;
        } else {
            this._donationType = null;
        }
    }

    set opportunities(value) {
        this._opportunities = value;
    }

    get opportunities() {
        return this._opportunities;
    }

    get hasPendingDonations() {
        if (!this.donorId) return false;
        return this.opportunities && this.opportunities.length > 0 ? true : false;
    }

    get reviewDonationsComputedClass() {
        let baseClass = ['slds-box', 'slds-theme_shade', 'slds-m-bottom_small'];

        if (this.hasSelectedDonation) {
            baseClass.push('slds-box_extension-2');
        } else {
            baseClass.push('slds-box_extension');
        }

        return baseClass.join(' ');
    }

    get isUpdatingPayment() {
        return this._donationType === PAYMENT.objectApiName ? true : false;
    }

    get isUpdatingOpportunity() {
        return this._donationType === OPPORTUNITY.objectApiName &&
            !this.selectedDonation.hasOwnProperty('applyPayment') &&
            !this.selectedDonation.hasOwnProperty('new') ?
            true :
            false;
    }

    get isApplyingNewPayment() {
        return this._donationType === OPPORTUNITY.objectApiName &&
            this.selectedDonation.hasOwnProperty('applyPayment') ?
            true :
            false;
    }

    get isCreatingNewOpportunity() {
        return this._donationType === OPPORTUNITY.objectApiName &&
            this.selectedDonation.hasOwnProperty('new') ?
            true :
            false;
    }

    get hasSelectedDonation() {
        return this.selectedDonation ? true : false;
    }

    get reviewDonationsMessage() {
        if (this._donor) {
            if (this.isCreatingNewOpportunity) {
                return this.CUSTOM_LABELS.geBodyMatchingNewOpportunity;
            }

            if (this.isApplyingNewPayment) {
                return this.CUSTOM_LABELS.geBodyMatchingApplyNewPayment;
            }

            if (this.isUpdatingOpportunity || this.isUpdatingPayment) {
                return this.CUSTOM_LABELS.geBodyMatchingUpdatingDonation;
            }
        }

        return this.CUSTOM_LABELS.geBodyMatchingPendingDonation;
    }

    get showDonorLink() {
        return this.isApplyingNewPayment ||
            this.isUpdatingOpportunity ||
            this.isUpdatingPayment ?
            true :
            false;
    }

    /*******************************************************************************
    * @description Method constructs and dispatches an object (modalConfig) as part
    * of an event to the parent component. This object (modalConfig) is then used to
    * configure the modal created by the aura overlay library in the parent aura
    * component.
    * 
    * modalConfig has two main properties, componentProperties and
    * modalProperties. componentProperties holds all the data for public (@api decorated)
    * properties in the lightning web component that's to be created within the modal
    * body. modalProperties holds all the data for the actual modal created by the 
    * overlay library.
    */
    openReviewDonationsModal() {
        const donorRecordName = this._donor ? this._donor.fields.Name.value : '';
        const modalHeader = geLabelService.format(
            this.CUSTOM_LABELS.geHeaderMatchingReviewDonations,
            [donorRecordName]);
        const modalConfig = {
            componentProperties: {
                opportunities: this.opportunities,
                dedicatedListenerEventName: this._dedicatedListenerEventName,
                selectedDonationId: this.hasSelectedDonation ? this.selectedDonation.Id : undefined
            },
            modalProperties: {
                cssClass: 'slds-modal_large',
                header: modalHeader,
                componentName: 'geDonationMatching',
                showCloseButton: true
            }
        };

        this.dispatchEvent(new CustomEvent('togglemodal', { detail: modalConfig }));
    }

    /*******************************************************************************
    * @description Method generates a record detail page url based on the currently
    * selected donor (Account or Contact) and either opens a new tab or a new window
    * depending on the user's browser settings.
    */
    navigateToRecord() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.selectedDonation.Id,
                actionName: 'view',
            },
        })
            .then(url => {
                window.open(url, '_blank');
            })
            .catch(error => {
                handleError(error);
            });
    }

    /*******************************************************************************
    * @description Resets properties for the currently selected donation and type.
    */
    handleResetReviewDonationsComponent() {
        this.selectedDonation = null;
        this._donationType = null;
        if (!this.donorId) {
            this.opportunities = [];
        }
    }

    // ================================================================================
    // AUTOMATION LOCATOR GETTERS
    // ================================================================================

    get qaLocatorSelectedDonation() {
        return `button ${this.selectedDonation.Name}`;
    }

    get qaLocatorReviewDonations() {
        return `button ${this.CUSTOM_LABELS.geButtonMatchingReviewDonations}`;
    }

    get qaLocatorDifferentSelection() {
        return `button ${this.CUSTOM_LABELS.geButtonMatchingUpdateDonationSelection}`;
    }
}