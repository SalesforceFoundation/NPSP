import { LightningElement, api, track, wire } from 'lwc';
import { mutable, inputTypeByDescribeType, showToast, dispatch } from 'c/utilTemplateBuilder';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import TemplateBuilderService from 'c/geTemplateBuilderService';

export default class geTemplateBuilderFormField extends LightningElement {
    @api isFirst;
    @api isLast;
    @track field;

    @api
    set field(field) {
        this.field = field;
    }

    wiredAdapterArgs;

    renderedCallback() {
        if (!this.wiredAdapterArgs && this.field && this.field.fieldInfo) {
            this.wiredAdapterArgs = this.field.fieldInfo;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$wiredAdapterArgs.defaultRecordTypeId',
        fieldApiName: '$wiredAdapterArgs'
    })
    wiredPicklistOptions({ error, data }) {
        if (data) {
            const picklistOptions = data.values;

            if (picklistOptions) {
                let field = mutable(this.field);
                field.picklistOptions = picklistOptions;
                this.field = field;
                let detail = {
                    fieldName: this.name,
                    property: 'picklistOptions',
                    value: picklistOptions
                }

                dispatch(this, 'updateformelement', detail);
            }
        }
    }

    get name() {
        if (this.field.elementType === 'widget') {
            return this.field.componentName;
        }

        // Used for field mappings
        if (this.field.dataImportFieldMappingDevNames && this.field.dataImportFieldMappingDevNames[0]) {
            return this.field.dataImportFieldMappingDevNames[0];
        }

        // Used for standard/custom fields (i.e. DataImportBatch__c fields)
        if (this.field.apiName) {
            return this.field.apiName;
        }

        return null;
    }

    get fieldMapping() {
        return TemplateBuilderService.fieldMappingByDevName[this.name] ? TemplateBuilderService.fieldMappingByDevName[this.name] : null;
    }

    get targetFieldApiName() {
        return this.fieldMapping.Target_Field_API_Name ? this.fieldMapping.Target_Field_API_Name : null;
    }

    get objectApiName() {
        return this.fieldMapping.Target_Object_API_Name ? this.fieldMapping.Target_Object_API_Name : null;
    }

    get isRequired() {
        return (this.field.required === 'Yes' || this.field.required === true) ? true : false;
    }

    get isRemovable() {
        return (this.field.isRequiredFieldDisabled === false || !this.field.isRequiredFieldDisabled) ? true : false;
    }

    get isWidget() {
        return this.field.elementType === 'widget' ? true : false;
    }

    get isLightningTextarea() {
        return this.lightningInputType === 'textarea' ? true : false;
    }

    get isLightningCombobox() {
        return this.lightningInputType === 'combobox' ? true : false;
    }

    get isLightningSearch() {
        return this.lightningInputType === 'search' ? true : false;
    }

    get isLightningRichText() {
        return this.lightningInputType === 'richtext' ? true : false;
    }

    get isLightningCheckbox() {
        return this.lightningInputType === 'checkbox' ? true : false;
    }

    get isLightningDateOrDatetime() {
        return (this.lightningInputType === 'date' || this.lightningInputType === 'datetime') ? true : false;
    }

    get isLightningInput() {
        if (this.lightningInputType !== 'textarea' &&
            this.lightningInputType !== 'combobox' &&
            this.lightningInputType !== 'richtext' &&
            this.lightningInputType !== 'search' &&
            this.lightningInputType !== 'checkbox' &&
            this.lightningInputType !== 'date' &&
            this.lightningInputType !== 'datetime') {
            return true;
        }
        return false;
    }

    get lightningInputType() {
        return this.field.dataType ? inputTypeByDescribeType[this.field.dataType.toLowerCase()] : 'text';
    }

    get defaultValueForCheckbox() {
        return (this.field.defaultValue === 'true' || this.field.defaultValue === true) ? true : false;
    }

    // TODO: Needs to be completed for lookup fields
    handleSearch(event) {
        event.stopPropagation();
        console.log('handle search');
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            showToast(this, 'Search Test', event.target.value, 'warning');
        }
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

        if (this.field.dataType && this.field.dataType.toLowerCase() === 'boolean') {
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
        let detail = {id: this.field.id, fieldName: this.name};
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