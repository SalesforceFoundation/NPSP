import { LightningElement, api } from 'lwc';
import { getQueryParameters, deepClone, isEmpty } from 'c/utilCommon';
import { dispatch, handleError } from 'c/utilTemplateBuilder';
import GeLabelService from 'c/geLabelService';

const EVENT_TOGGLE_MODAL = 'togglemodal';
const SAVE = 'save';
const GIFT_ENTRY = 'Gift_Entry';
const TEMPLATE_BUILDER = 'Template_Builder';
const SINGLE_GIFT_ENTRY = 'Single_Gift_Entry';

export default class geHome extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    view = GIFT_ENTRY;
    recordId;

    get isLandingPage() {
        return this.view === GIFT_ENTRY ? true : false;
    }

    get isTemplateBuilder() {
        return this.view === TEMPLATE_BUILDER ? true : false;
    }

    get isSingleGiftEntry() {
        return this.view === SINGLE_GIFT_ENTRY ? true : false;
    }

    connectedCallback() {
        console.log('*************--- connectedCallback');
        const queryParameters = getQueryParameters();
        console.log('queryParameters: ', queryParameters);
        if (!isEmpty(queryParameters)) {
            this.handleCurrentView(queryParameters);
        }
    }

    handleChangeView(event) {
        console.log('********--- handleChangeView');
        console.log('Detail: ', deepClone(event.detail));
        this.view = event.detail.view;
        if (this.view === TEMPLATE_BUILDER && event.detail.recordId) {
            this.recordId = event.detail.recordId;
        } else {
            this.recordId = undefined;
        }
    }

    handleCurrentView(queryParameters) {
        const view = queryParameters.c__view;

        if (view === 'Gift_Entry') {
            this.view = 'Gift_Entry';
        } else if (view === 'Template_Builder') {
            this.view = 'Template_Builder';
        } else if (view === 'Single_Gift_Entry') {
            this.view = 'Single_Gift_Entry';
        }
    }

    /*******************************************************************************
    * @description Public method for receiving modal related events from geListView.
    *
    * @param {object} modalData: Event object containing the action and modal payload.
    * component chain: utilDualListbox -> geListView -> here.
    */
    @api
    notify(event) {
        console.log('*******--- notify: ', deepClone(event));
        if (event.componentChain && event.componentChain.length > 0) {
            const component = this.template.querySelector(`c-${event.componentChain[0]}`);
            if (component) {
                event.componentChain.shift();
                component.notify(event);
            }
        }
    }

    /*******************************************************************************
    * @description Pass through method that receives an event from geListView to
    * notify parent aura component to construct a modal.
    *
    * @param {object} event: Event object containing a payload for the modal.
    */
    toggleModal(event) {
        console.log('toggleModal');
        dispatch(this, EVENT_TOGGLE_MODAL, event.detail);
    }
}