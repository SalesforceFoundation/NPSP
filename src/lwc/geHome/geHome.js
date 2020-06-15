import { LightningElement, api, track } from 'lwc';
import { getQueryParameters } from 'c/utilCommon';
import {
    dispatch,
    getPageAccess,
    EVENT_SOURCE_LIST_VIEW,
    EVENT_SOURCE_APPLICATION } from 'c/utilTemplateBuilder';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import GeLabelService from 'c/geLabelService';
import { fireEvent, registerListener } from 'c/pubsubNoPageRef'

const EVENT_TOGGLE_MODAL = 'togglemodal';
const DEFAULT_FIELD_MAPPING_SET = 'Migrated_Custom_Field_Mapping_Set';
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
    @track hasPageAccess = true;
    @track hasPermission = true;
    @track isListViewAccessible = true;
    _listViewPermissionErrorHeader;
    _listViewPermissionErrorBody;
    _appPermissionErrorHeader;
    _appPermissionErrorBody;

    giftEntryTabName;

    get isLandingPage() {
        return this.view === GIFT_ENTRY;
    }

    get isTemplateBuilder() {
        return this.view === TEMPLATE_BUILDER;
    }

    get isAppAccessible () {
       return (this.hasPageAccess && this.hasPermission);
    }


    async connectedCallback() {
        this.hasPageAccess = await getPageAccess();
        registerListener('appPermissionsChange', this.handleAppPermissionsChange, this);
        if (this.isAppAccessible) {
            await TemplateBuilderService.init(DEFAULT_FIELD_MAPPING_SET);
            this.setGiftEntryTabName();
            this.setInitialView();
        } else if (!this.hasPageAccess) {
            this._appPermissionErrorHeader =
              this.CUSTOM_LABELS.geErrorPageLevelAdvancedMappingHeader;
            this._appPermissionErrorBody =
              this.CUSTOM_LABELS.geErrorPageLevelAdvancedMappingBody;
        }
        this.isLoading = false;
    }

    /*******************************************************************************
    * @description Method sets the Gift Entry tab name with the proper namespace.
    */
    setGiftEntryTabName() {
        this.giftEntryTabName = TemplateBuilderService.alignSchemaNSWithEnvironment(GIFT_ENTRY_TAB_NAME);
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

    handleAppPermissionsChange(event) {
        this.setAppPermissionErrors(event);

    }

    /**
     * @description Set permission (CRUD & FLS) errors for the geListView component
     * @param {object} event : Event object containing the error message
     */
    setAppPermissionErrors(event) {
        if (event) {
            if (this.view === SINGLE_GIFT_ENTRY) {
                fireEvent(null, 'geFormAccessChange',
                  {
                      messageBody: event.messageBody,
                      messageHeader: event.messageHeader,
                  });
            } else {
                if (event.source === EVENT_SOURCE_APPLICATION) {
                    this.hasPermission = false;
                    this._appPermissionErrorHeader = event.messageHeader;
                    this._appPermissionErrorBody = event.messageBody;
                } else if (event.source === EVENT_SOURCE_LIST_VIEW) {
                    this.isListViewAccessible = false;
                    this._listViewPermissionErrorBody = event.messageBody;
                    this._listViewPermissionErrorHeader = event.messageHeader;
                }
            }
        }
    }
}