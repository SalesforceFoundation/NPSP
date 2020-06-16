import { api, LightningElement } from 'lwc'
import { mutable } from 'c/utilCommon'
import { fireEvent } from 'c/pubsubNoPageRef'
import GeLabelService from 'c/geLabelService'

const DISPLAY_MODES = {
    expanded : 'expanded',
    collapsed : 'collapsed'
}

export default class GeTemplateBuilderSectionModalBody extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api modalData;
    _selectedDisplayMode;

    connectedCallback () {
        if (this.sectionBeingEdited) {
            this._selectedDisplayMode = this.defaultDisplayMode;
        }
    }

    get defaultDisplayMode () {
        return this.modalData.section ?
          this.modalData.section.defaultDisplayMode : DISPLAY_MODES.expanded;
    }

    get sectionBeingEdited() {
        return this.modalData ? this.modalData.section : {};
    }

    get hasRequiredFields() {
        const section = this.modalData.section;
        return section && section.elements && section.elements.length > 0 ?
            section.elements.some(element => element.required === true)
            : false;
    }

    /*******************************************************************************
    * Start getters for data-qa-locator attributes
    */

    get qaLocatorSectionName() {
        return `input ${this.CUSTOM_LABELS.geHeaderFormFieldsModalSectionSettings} ${this.CUSTOM_LABELS.geLabelSectionName}`;
    }

    get qaLocatorDelete() {
        return `button ${this.CUSTOM_LABELS.geHeaderFormFieldsModalSectionSettings} ${this.CUSTOM_LABELS.geButtonFormFieldsModalDeleteSectionAndFields}`;
    }

    get qaLocatorCancel() {
        return `button ${this.CUSTOM_LABELS.geHeaderFormFieldsModalSectionSettings} ${this.CUSTOM_LABELS.commonCancel}`;
    }

    get qaLocatorSave() {
        return `button ${this.CUSTOM_LABELS.geHeaderFormFieldsModalSectionSettings} ${this.CUSTOM_LABELS.commonSave}`;
    }

    get qaLocatorDisplayOption() {
      //TODO: Add qa locator for display options
    }

    /*******************************************************************************
    * End getters for data-qa-locator attributes
    */

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener to notify parent aura
    * component GE_ModalProxy that the given section needs to be removed.
    */
    handleDelete() {
        const detail = {
            receiverComponent: this.modalData.receiverComponent,
            action: 'delete',
            section: this.modalData.section
        };
        fireEvent(this.pageRef, 'geTemplateBuilderSectionModalBodyEvent', detail);
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener to notify parent aura
    * component GE_ModalProxy that the modal needs to be updated.
    */
    handleSave() {
        let section = mutable(this.modalData.section);

        section.label = this.template.querySelector('lightning-input[data-name="customLabel"]').value;
        section.defaultDisplayMode = this._selectedDisplayMode;
        const detail = {
            receiverComponent: this.modalData.receiverComponent,
            action: 'save',
            section: section
        };
        fireEvent(this.pageRef, 'geTemplateBuilderSectionModalBodyEvent', detail);
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener to notify parent aura
    * component GE_ModalProxy that the modal needs to be closed.
    */
    handleCancel() {
        const detail = { action: 'cancel' };
        fireEvent(this.pageRef, 'geTemplateBuilderSectionModalBodyEvent', detail);
    }

    get displayOptions() {
        return [
            { label: this.CUSTOM_LABELS.geButtonFormFieldsDisplayOptionExpanded,
                value: DISPLAY_MODES.expanded },
            { label: this.CUSTOM_LABELS.geButtonFormFieldsDisplayOptionCollapsed,
                value: DISPLAY_MODES.collapsed },
        ];
    }

    /**
     * @description Sets the selected section display option
     * @param event
     */
    handleDisplayOptionChange (event) {
        this._selectedDisplayMode = event.detail.value;
    }
}