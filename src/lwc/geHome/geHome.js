import { LightningElement, api, track } from 'lwc';
import { getQueryParameters, getNamespace } from 'c/utilCommon';
import { dispatch, getPageAccess } from 'c/utilTemplateBuilder';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import GeLabelService from 'c/geLabelService';
import DataImport from '@salesforce/schema/DataImport__c';
import { registerListener } from 'c/pubsubNoPageRef'

const EVENT_TOGGLE_MODAL = 'togglemodal';
const GIFT_ENTRY_TAB_NAME = 'GE_Gift_Entry';
const GIFT_ENTRY = 'Gift_Entry';
const TEMPLATE_BUILDER = 'Template_Builder';
const SINGLE_GIFT_ENTRY = 'Single_Gift_Entry';

export default class geHome extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @track view = GIFT_ENTRY;
    @track formTemplateId;
    @track cloneFormTemplate;
    @track isLoading = true;
    @track isAppAccessible = true;
    @track isListViewAccessible = true;
    _listViewPermissionErrorHeader;
    _listViewPermissionErrorBody;

    giftEntryTabName;

    get isLandingPage() {
        return this.view === GIFT_ENTRY ? true : false;
    }

    get isTemplateBuilder() {
        return this.view === TEMPLATE_BUILDER ? true : false;
    }

    async connectedCallback() {
        registerListener('listViewPermissionsChange',
          this.handleListViewPermissionsChange, this);
        this.isAppAccessible = await getPageAccess();
        if (this.isAppAccessible) {
            this.setGiftEntryTabName();
            this.setInitialView();
        }
        this.isLoading = false;
    }

    /*******************************************************************************
    * @description Method sets the Gift Entry tab name with the proper namespace.
    */
    setGiftEntryTabName() {
        this.giftEntryTabName =
            TemplateBuilderService.alignSchemaNSWithEnvironment(
                GIFT_ENTRY_TAB_NAME, this.namespace);
    }

    /*******************************************************************************
    * @description Method handles setting the initial view based on url parameters
    * if there are any.
    */
    setInitialView() {
        const queryParameters = getQueryParameters();
        if (queryParameters && queryParameters.c__view) {
            this.view = queryParameters.c__view;
        }
        if (this.view === SINGLE_GIFT_ENTRY) {
            this.dispatchEvent(new CustomEvent('newsinglegift'));
        }
    }

    /*******************************************************************************
    * @description Method handles changing the current view based on parameters
    * in the received event.
    *
    * @param {object} event: Event object containing parameters like 'c__view',
    * 'c__formTemplateRecordId', 'c__donorRecordId', etc used to change the current
    * view and set the respective view record id.
    */
    handleChangeView(event) {
        this.resetUrlParameters();

        this.view = event.detail.view;
        if (this.view === TEMPLATE_BUILDER && event.detail.formTemplateId) {
            this.formTemplateId = event.detail.formTemplateId;
            this.cloneFormTemplate = event.detail.clone;
        } else if (this.view === SINGLE_GIFT_ENTRY) {
            this.dispatchEvent(new CustomEvent('newsinglegift'));
        } else {
            this.formTemplateId = undefined;
        }
    }

    /*******************************************************************************
    * @description Method clears out any query parameters in the url.
    */
    resetUrlParameters() {
        window.history.pushState({}, document.title, this.giftEntryTabName);
    }

    /*******************************************************************************
    * @description Public method for receiving modal related events from geListView.
    *
    * @param {object} modalData: Event object containing the action and modal payload.
    * component chain: utilDualListbox -> geListView -> here.
    */
    @api
    notify(event) {
        if (event.receiverComponent && event.receiverComponent.length > 0) {
            const component = this.template.querySelector(`c-${event.receiverComponent}`);
            if (component) {
                component.notify(event);
            }
        }
    }

    /*******************************************************************************
    * @description Pass through method that receives an event from child components
    * to notify the parent aura component to construct a modal.
    *
    * @param {object} event: Event object containing a payload for the modal.
    */
    toggleModal(event) {
        dispatch(this, EVENT_TOGGLE_MODAL, event.detail);
    }

    handleListViewPermissionsChange(event) {
        this.setListViewPermissionErrors(event);
    }

    /**
     * @description Set permission (CRUD & FLS) errors for the geListView component
     * @param {object} event : Event object containing the error message
     */
    setListViewPermissionErrors(event) {
        this.isListViewAccessible = false;
        if (event) {
            this._listViewPermissionErrorBody = event.messageBody;
            this._listViewPermissionErrorHeader = event.messageHeader;
        }
    }

    get namespace() {
        return getNamespace(DataImport.objectApiName);
    }

}