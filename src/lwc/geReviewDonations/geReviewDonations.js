import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { handleError } from 'c/utilTemplateBuilder';
import { deepClone } from 'c/utilCommon';
import geLabelService from 'c/geLabelService';

const PAYMENT = 'payment';
const OPPORTUNITY = 'opportunity';

export default class geReviewDonations extends NavigationMixin(LightningElement) {

    CUSTOM_LABELS = geLabelService.CUSTOM_LABELS;

    @api donorId;
    @api dedicatedListenerEventName = 'geDonationMatchingEvent';
    @api selectedDonation;
    @api opportunities;

    @track donationType;
    @track donor;

    @wire(getRecord, { recordId: '$donorId', optionalFields: ['Account.Name', 'Contact.Name'] })
    wiredGetRecordMethod({ error, data }) {
        if (data) {
            this.donor = data;
        } else if (error) {
            handleError(error);
        }
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
        const donorRecordName = this.donor ? this.donor.fields.Name.value : '';
        const modalHeader = geLabelService.format(
            this.CUSTOM_LABELS.geHeaderMatchingReviewDonations,
            [donorRecordName]);
        const modalConfig = {
            componentProperties: {
                opportunities: deepClone(this.opportunities),
                dedicatedListenerEventName: this.dedicatedListenerEventName,
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
            selectedDonation: deepClone(this.selectedDonation),
            donationType: deepClone(this.donationType)
        }

        this.dispatchEvent(new CustomEvent('changeselecteddonation', { detail }));
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

    @api
    resetDonationType() {
        this.donationType = undefined;
    }
}