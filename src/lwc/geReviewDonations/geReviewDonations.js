import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { dispatch, handleError } from 'c/utilTemplateBuilder';
import { deepClone } from 'c/utilCommon';
import geLabelService from 'c/geLabelService';

const EVENT_TOGGLE_MODAL = 'togglemodal';
const PAYMENT = 'payment';
const OPPORTUNITY = 'opportunity';

export default class geReviewDonations extends NavigationMixin(LightningElement) {

    CUSTOM_LABELS = geLabelService.CUSTOM_LABELS;

    // TODO: donor is a temporary object used for dev. Needs to be replaced by a real donor
    // object passed in from the outer/parent component.
    @api donor = {
        Id: '0033D00000b9vjVQAQ',
        Name: 'Baby Yoda'
    };
    @api recordId = '0013D00000pwpJgQAI';
    @api dedicatedListenerEventName = 'geDonationMatchingEvent';
    @api selectedDonation;
    @api opportunities;

    @track donationType;

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
        return this.donationType === PAYMENT ? true : false;
    }

    get isUpdatingOpportunity() {
        return this.donationType === OPPORTUNITY &&
            !this.selectedDonation.hasOwnProperty('applyPayment') &&
            !this.selectedDonation.hasOwnProperty('new') ?
            true :
            false;
    }

    get isApplyingNewPayment() {
        return this.donationType === OPPORTUNITY &&
            this.selectedDonation.hasOwnProperty('applyPayment') ?
            true :
            false;
    }

    get isCreatingNewOpportunity() {
        return this.donationType === OPPORTUNITY &&
            this.selectedDonation.hasOwnProperty('new') ?
            true :
            false;
    }

    get hasSelectedDonation() {
        return this.donationType ? true : false;
    }

    get reviewDonationsMessage() {
        if (this.donor) {
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

    get hasDonorLink() {
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
    handleReviewDonations() {
        // TODO: Pass the opp and/or the payment id when updating donation selection
        // TODO: Add CSS to highlight selected opp/payment card based on id as received in above TODO.
        const modalHeader = this.CUSTOM_LABELS.geHeaderMatchingReviewDonations;
        const modalConfig = {
            componentProperties: {
                opportunities: deepClone(this.opportunities),
                dedicatedListenerEventName: this.dedicatedListenerEventName,
            },
            modalProperties: {
                cssClass: 'slds-modal_large',
                header: modalHeader,
                componentName: 'geDonationMatching',
                showCloseButton: true
            }
        };

        dispatch(this, EVENT_TOGGLE_MODAL, modalConfig);
    }

    /*******************************************************************************
    * @description Method receives an event from the child geDonationMatching
    * component and sets the currently selected donation along with its type.
    * 
    * @param {object} event: Custom Event object received from child component.
    */
    handleReceiveEvent(event) {
        if (event.detail.hasOwnProperty(PAYMENT)) {
            this.selectedDonation = event.detail.payment;
            this.donationType = PAYMENT;
        } else if (event.detail.hasOwnProperty(OPPORTUNITY)) {
            this.selectedDonation = event.detail.opportunity;
            this.donationType = OPPORTUNITY;
        } else {
            this.selectedDonation = this.donationType = undefined;
        }

        const detail = {
            selectedDonation: this.selectedDonation,
            donationType: this.donationType
        }

        dispatch(this, 'changeselecteddonation', detail);
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
}