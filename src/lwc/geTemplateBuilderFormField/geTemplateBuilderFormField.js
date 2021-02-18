import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {dispatch, isTrueFalsePicklist, isCheckboxToCheckbox, trueFalsePicklistOptions} from 'c/utilTemplateBuilder';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import GeLabelService from 'c/geLabelService';
import {isEmpty} from 'c/utilCommon';
import hasViewSetup from '@salesforce/userPermission/ViewSetup';

import DATA_IMPORT_BATCH from '@salesforce/schema/DataImportBatch__c';

const WIDGET = 'widget';
const YES = 'Yes';
const FIELD_METADATA_VALIDATION = 'fieldmetadatavalidation';


export default class geTemplateBuilderFormField extends LightningElement {
    @track targetObjectDescribeInfo;

    @api isFirst;
    @api isLast;
    @api objectApiName;
    @api field;
    @api sourceObjectFieldsDescribe;

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    isBatchHeaderField = false;
    hasRendered = false;
    hasPermission = hasViewSetup;
    shouldRender = true;


    /*******************************************************************************
    * @description Retrieves the target object's describe data. Used to get the
    * picklist options for picklist fields. See component geFormFieldPicklist.
    *
    * @param {string} targetObjectApiName: Field's object api name.
    */
    @wire(getObjectInfo, { objectApiName: '$targetObjectApiName' })
    wiredObjectInfo(response) {
        if (response.data) {
            this.targetObjectDescribeInfo = response.data;

            this.validate();
        }
    }

    renderedCallback() {
        if (!this.hasRendered) {
            this.hasRendered = true;

            if (this.objectApiName === DATA_IMPORT_BATCH.objectApiName) {
                return;
            }

            if (isEmpty(this.fieldMapping)) {
                const inputField = this.template.querySelector('[data-id="formField"]');

                inputField.setCustomValidity(this.CUSTOM_LABELS.commonFieldNotFound);
                inputField.reportValidity();

                this.dispatchEvent(new CustomEvent(FIELD_METADATA_VALIDATION, {detail: {showError: true}}));
            }
        }
    }

    /*******************************************************************************
     * @description Performs form field-level validations that require data not present in the parent component
     * such as target object describe metadata.
     */
    validate() {
        if (isEmpty(this.fieldMapping)) {
            return;
        }

        if (isEmpty(this.targetObjectDescribeInfo.fields[this.fieldMapping.Target_Field_API_Name]) ||
            isEmpty(this.sourceObjectFieldsDescribe[this.fieldMapping.Source_Field_API_Name])) {

            const inputField = this.template.querySelector('[data-id="formField"]');

            inputField.setCustomValidity(this.CUSTOM_LABELS.commonFieldNotFound);
            inputField.reportValidity();

            if (!hasViewSetup) {
                this.field = {};
                this.shouldRender = false;
            }

            this.dispatchEvent(new CustomEvent(FIELD_METADATA_VALIDATION, {detail: {showError: true}}));
        }
    }

    get cssClassCard() {
        if (this.field.elementType === WIDGET) {
            return 'slds-card slds-card_extension slds-card_extension-widget slds-m-vertical_small';
        } else {
            return 'slds-card slds-card_extension slds-m-vertical_small';
        }
    }

    get cssClassActionsContainer() {
        if (this.field.elementType === WIDGET) {
            return 'slds-size_1-of-12 vertical-align-center'
        } else {
            return 'slds-size_1-of-12 slds-p-bottom_x-small';
        }
    }

    get cssClassRenderedWidget() {
        if (this.isWidget) {
            return 'slds-size_10-of-12 slds-p-right_small';
        } else {
            return 'slds-size_5-of-12 slds-p-right_small';
        }
    }

    get name() {
        if (this.field.elementType === WIDGET) {
            return this.field.componentName;
        }

        // Used for field mappings
        if (this.field.dataImportFieldMappingDevNames && this.field.dataImportFieldMappingDevNames[0]) {
            return this.field.dataImportFieldMappingDevNames[0];
        }

        // Used for standard/custom fields (i.e. DataImportBatch__c fields)
        if (this.field.apiName) {
            this.isBatchHeaderField = true;
            return this.field.apiName;
        }

        return null;
    }

    get fieldApiName() {
        if (this.field && this.field.apiName) {
            return this.field.apiName;
        }

        if (this.field && this.field.fieldApiName) {
            return this.field.fieldApiName;
        }
    }

    get labelHelpText() {
        if (this.fieldMapping && this.fieldMapping.Target_Object_Mapping_Dev_Name) {
            const objectMapping =
                TemplateBuilderService.objectMappingByDevName[this.fieldMapping.Target_Object_Mapping_Dev_Name];
            const targetObjectApiName =
                this.fieldMapping.Target_Object_API_Name || objectMapping.Object_API_Name;

            return GeLabelService.format(
                this.CUSTOM_LABELS.geHelpTextFormFieldsFieldCustomLabel,
                [
                    objectMapping.MasterLabel,
                    this.fieldMapping.Target_Field_API_Name,
                    targetObjectApiName
                ]);
        }
        return null;
    }

    get fieldMapping() {
        return TemplateBuilderService.fieldMappingByDevName[this.name] ? TemplateBuilderService.fieldMappingByDevName[this.name] : null;
    }

    get targetFieldApiName() {
        if (this.fieldMapping && this.fieldMapping.Target_Field_API_Name) {
            return this.fieldMapping.Target_Field_API_Name;
        }

        if (this.field && this.field.apiName) {
            return this.field.apiName;
        }

        return null;
    }

    get targetObjectApiName() {
        if (this.fieldMapping && this.fieldMapping.Target_Object_API_Name) {
            return this.fieldMapping.Target_Object_API_Name;
        }

        if (this.objectApiName) {
            return this.objectApiName;
        }

        return null;
    }

    get isRequired() {
        return (this.field.required === YES || this.field.required === true);
    }

    get isDisabled() {
        return this.field.isRequiredFieldDisabled ? true : false;
    }

    get isWidget() {
        return this.field.elementType === WIDGET;
    }

    get showRequiredCheckbox() {
        return !this.isWidget && !isCheckboxToCheckbox(this.fieldMapping);
    }

    get showDefaultValueInput() {
        return !isCheckboxToCheckbox(this.fieldMapping);
    }

    get picklistOptionsOverride() {
        if (isTrueFalsePicklist(this.fieldMapping)) {
            return trueFalsePicklistOptions();
        }
    }

    get labelGeAssistiveFormFieldRemove() {
        const customLabel =
            this.isBatchHeaderField ?
                this.CUSTOM_LABELS.geAssistiveBatchHeaderRemoveField
                : this.CUSTOM_LABELS.geAssistiveFormFieldsRemoveField;

        return GeLabelService.format(customLabel, [this.field.label]);
    }

    get labelGeAssistiveFormFieldUp() {
        return GeLabelService.format(this.CUSTOM_LABELS.geAssistiveFieldUp, [this.field.label]);
    }

    get labelGeAssistiveFormFieldDown() {
        return GeLabelService.format(this.CUSTOM_LABELS.geAssistiveFieldDown, [this.field.label]);
    }

    get labelGeAssistiveRequireField() {
        return GeLabelService.format(this.CUSTOM_LABELS.geAssistiveRequireField, [this.field.label]);
    }

    get labelGeAssistiveRequiredCheckboxDescription() {
        if (this.isRequired) {
            return GeLabelService.format(this.CUSTOM_LABELS.geAssistiveDescriptionFieldRequired, [this.field.label]);
        } else {
            return GeLabelService.format(this.CUSTOM_LABELS.geAssistiveDescriptionFieldOptional, [this.field.label]);
        }
    }

    /*******************************************************************************
    * Start getters for data-qa-locator attributes
    */

    get qaLocatorInputFieldLabel() {
        return `input ${this.CUSTOM_LABELS.commonFieldLabel} ${this.field.label}`;
    }

    get qaLocatorInputDefaultValue() {
        return `input ${this.CUSTOM_LABELS.commonDefaultValue} ${this.field.label}`;
    }

    get qaLocatorCheckboxRequired() {
        return `checkbox ${this.CUSTOM_LABELS.commonRequired} ${this.field.label}`;
    }

    get qaLocatorButtonDelete() {
        return `button Delete ${this.field.label}`;
    }

    get qaLocatorButtonUp() {
        return `button Up ${this.field.label}`;
    }

    get qaLocatorButtonDown() {
        return `button Down ${this.field.label}`;
    }

    /*******************************************************************************
    * End getters for data-qa-locator attributes
    */

    stopPropagation(event) {
        event.stopPropagation();
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's required property has changed.
    *
    * @param {object} event: Event object from lightning-input checkbox onchange
    * event handler 
    */
    handleOnChangeRequiredField(event) {
        this.stopPropagation(event);
        let detail = {
            fieldName: this.name,
            property: 'required',
            value: event.target.checked
        }

        dispatch(this, 'updateformelement', detail);
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's defaultValue property has changed.
    *
    * @param {object} event: Event object from various lightning-input type's
    * onblur event handler 
    */
    handleOnChange(event) {
        let detail = {
            fieldName: this.name,
            property: 'defaultValue',
            value: event.detail.value
        }

        dispatch(this, 'updateformelement', detail);
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's customLabel property has changed.
    *
    * @param {object} event: Event object from lightning-input onblur event handler 
    */
    handleOnBlurCustomLabel(event) {
        let detail = {
            fieldName: this.name,
            property: 'customLabel',
            value: event.target.value
        }
        dispatch(this, 'updateformelement', detail);
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's needs to be removed.
    *
    * @param {object} event: Event object from lightning-button-icon onclick event handler
    */
    handleDeleteFormElement(event) {
        this.stopPropagation(event);
        let detail = { id: this.field.id, fieldName: this.name };
        dispatch(this, 'deleteformelement', detail);

        this.dispatchEvent(new CustomEvent(FIELD_METADATA_VALIDATION, {detail: {showError: false}}));
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's needs to be moved up.
    *
    * @param {object} event: Event object from lightning-button-icon onclick event handler
    */
    handleFormElementUp(event) {
        this.stopPropagation(event);
        dispatch(this, 'formelementup', this.name);
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's needs to be moved down.
    *
    * @param {object} event: Event object from lightning-button-icon onclick event handler
    */
    handleFormElementDown(event) {
        this.stopPropagation(event);
        dispatch(this, 'formelementdown', this.name);
    }
}
