import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { inputTypeByDescribeType, dispatch } from 'c/utilTemplateBuilder';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import GeLabelService from 'c/geLabelService';

const WIDGET = 'widget';
const BOOLEAN = 'boolean';
const TEXTAREA = 'textarea';
const COMBOBOX = 'combobox';
const SEARCH = 'search';
const RICHTEXT = 'richtext';
const CHECKBOX = 'checkbox';
const DATE = 'date';
const DATETIME = 'datetime-local';
const YES = 'Yes';
const TEXT = 'text';
const TRUE = 'true';

export default class geTemplateBuilderFormField extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api isFirst;
    @api isLast;
    @api objectApiName;
    @api field;

    @track objectDescribeInfo;

    isBatchHeaderField = false;


    /*******************************************************************************
    * @description Retrieves the target object's describe data. Used to get the
    * picklist options for picklist fields. See component geFormFieldPicklist.
    *
    * @param {string} targetObjectApiName: Field's object api name.
    */
    @wire(getObjectInfo, { objectApiName: '$targetObjectApiName' })
    wiredObjectInfo(response) {
        if (response.data) {
            this.objectDescribeInfo = response.data;
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
        return (this.field.required === YES || this.field.required === true) ? true : false;
    }

    get isRemovable() {
        return (this.field.isRequiredFieldDisabled === false || !this.field.isRequiredFieldDisabled) ? true : false;
    }

    get isWidget() {
        return this.field.elementType === WIDGET ? true : false;
    }

    get isLightningTextarea() {
        return this.lightningInputType === TEXTAREA ? true : false;
    }

    get isLightningCombobox() {
        return this.lightningInputType === COMBOBOX ? true : false;
    }

    get isLightningSearch() {
        return this.lightningInputType === SEARCH ? true : false;
    }

    get isLightningRichText() {
        return this.lightningInputType === RICHTEXT ? true : false;
    }

    get isLightningCheckbox() {
        return this.lightningInputType === CHECKBOX ? true : false;
    }

    get isLightningDateOrDatetime() {
        return (this.lightningInputType === DATE || this.lightningInputType === DATETIME) ? true : false;
    }

    get isLightningInput() {
        if (this.lightningInputType !== TEXTAREA &&
            this.lightningInputType !== COMBOBOX &&
            this.lightningInputType !== RICHTEXT &&
            this.lightningInputType !== SEARCH &&
            this.lightningInputType !== CHECKBOX &&
            this.lightningInputType !== DATE &&
            this.lightningInputType !== DATETIME) {
            return true;
        }
        return false;
    }

    get lightningInputType() {
        return this.field.dataType ? inputTypeByDescribeType[this.field.dataType.toLowerCase()] : TEXT;
    }

    get defaultValueForCheckbox() {
        return (this.field.defaultValue === TRUE || this.field.defaultValue === true) ? true : false;
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
    * field's defaultValue property for a combobox has changed.
    *
    * @param {object} event: Event object from lightning-combobox onchange event handler 
    */
    handleChangeCombobox(event) {
        let detail = {
            fieldName: this.name,
            property: 'defaultValue',
            value: event.target.value
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
    handleOnBlur(event) {
        let value;

        if (this.field.dataType && this.field.dataType.toLowerCase() === BOOLEAN) {
            value = event.target.checked;
        } else {
            value = event.target.value;
        }

        let detail = {
            fieldName: this.name,
            property: 'defaultValue',
            value: value
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