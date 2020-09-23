import getRenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import getFormRenderWrapper from '@salesforce/apex/GE_GiftEntryController.getFormRenderWrapper';
import getAllocationSettings from '@salesforce/apex/GE_GiftEntryController.getAllocationsSettings';

import { handleError } from 'c/utilTemplateBuilder';
import { api } from 'lwc';
import { isNotEmpty, isEmpty } from 'c/utilCommon';

import OPPORTUNITY_AMOUNT from '@salesforce/schema/Opportunity.Amount';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';

// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_enum_Schema_DisplayType.htm
// this list only includes fields that can be handled by lightning-input
const inputTypeByDescribeType = {
    'BOOLEAN': 'checkbox',
    'CURRENCY': 'number',
    'DATE': 'date',
    'DATETIME': 'datetime-local',
    'EMAIL': 'email',
    'DOUBLE': 'number',
    'INTEGER': 'number',
    'LONG': 'number',
    'PERCENT': 'number',
    'STRING': 'text',
    'PHONE': 'tel',
    'TEXT': 'text',
    'TIME': 'time',
    'URL': 'url'
};

const numberFormatterByDescribeType = {
    'PERCENT': 'percent-fixed',
    'CURRENCY': 'currency',
    'DECIMAL': 'decimal'
};

class GeFormService {

    fieldMappings;
    objectMappings;
    fieldTargetMappings;
    donationFieldTemplateLabel;

    /**
     * Retrieve the default form render wrapper.
     * @returns {Promise<GE_GiftEntryController.RenderWrapper>}
     */
    @api
    getFormTemplate() {
        return new Promise((resolve, reject) => {
            getRenderWrapper({})
                .then((result) => {
                    this.fieldMappings = result.fieldMappingSetWrapper.fieldMappingByDevName;
                    this.objectMappings = result.fieldMappingSetWrapper.objectMappingByDevName;
                    this.fieldTargetMappings = result.fieldMappingSetWrapper.fieldMappingByTargetFieldName;
                    if (isEmpty(this.donationFieldTemplateLabel)) {
                        this.donationFieldTemplateLabel = this.getDonationAmountCustomLabel(result.formTemplate);
                    }
                    resolve(result);
                })
                .catch(error => {
                    handleError(error);
                });
        });
    }

    getAllocationSettings() {
        return new Promise((resolve, reject) => {
            getAllocationSettings()
                .then(resolve)
                .catch(handleError)
        });
    }

    /**
     * Get the type of lightning-input that should be used for a given field type.
     * @param dataType  Data type of the field
     * @returns {String}
     */
    getInputTypeFromDataType(dataType) {
        return inputTypeByDescribeType[dataType];
    }

    /**
     * Get the formatter for a lightning-input that should be used for a given field type
     * @param dataType  Data type of the field
     * @returns {String | undefined}
     */
    getNumberFormatterByDescribeType(dataType) {
        return numberFormatterByDescribeType[dataType];
    }

    /**
     * Get a field info object by dev name from the render wrapper object
     * @param fieldDevName  Dev name of the object to retrieve
     * @returns {BDI_FieldMapping}
     */
    getFieldMappingWrapper(fieldDevName) {
        return this.fieldMappings[fieldDevName];
    }

    /**
     * Get a field info object by dev name from the render wrapper object
     * @param fieldDevName  Dev name of the object to retrieve
     * @returns {BDI_FieldMapping}
     */
    getFieldMappingWrapperFromTarget(targetFieldName) {
        return this.fieldTargetMappings[targetFieldName];
    }

    /**
     * Get a object info object by dev name from the render wrapper object
     * @param objectDevName
     * @returns {BDI_ObjectMapping}
     */
    getObjectMappingWrapper(objectDevName) {
        return this.objectMappings[objectDevName];
    }

    /**
     * Get the user-defined label used for the Opportunity Amount field on the
     * @return {string}
     */
    getDonationAmountCustomLabel(formTemplate) {
        // find field that is mapped to Opportunity Amount
        const mapping = this.getFieldMappingWrapperFromTarget(`${OPPORTUNITY_OBJECT.objectApiName}.${OPPORTUNITY_AMOUNT.fieldApiName}`);
        const mappingDevName = mapping.DeveloperName;
        // get developer name of mapping cmt
        let fieldElement;
        for (const section of formTemplate.layout.sections) {
            fieldElement = section.elements.find(element => {
                if (Array.isArray(element.dataImportFieldMappingDevNames)) {
                    return element.dataImportFieldMappingDevNames.includes(mappingDevName);
                }
            });
        }

        if (isNotEmpty(fieldElement)) {
            // return custom label from the form template layout
            return fieldElement.customLabel;
        }
    }

    getFormRenderWrapper(templateId) {
        return new Promise((resolve, reject) => {
            getFormRenderWrapper({ templateId: templateId })
                .then(renderWrapper => {
                    this.fieldMappings =
                        renderWrapper.fieldMappingSetWrapper.fieldMappingByDevName;
                    this.objectMappings =
                        renderWrapper.fieldMappingSetWrapper.objectMappingByDevName;
                    this.fieldTargetMappings =
                        renderWrapper.fieldMappingSetWrapper.fieldMappingByTargetFieldName;
                    resolve(renderWrapper);
                })
                .catch(err => {
                    reject(err);
                });
        });

    }

    getFormTemplateById(templateId) {
        return new Promise((resolve, reject) => {
            this.getFormRenderWrapper(templateId)
                .then(renderWrapper => {
                    resolve(renderWrapper.formTemplate);
                })
                .catch(err => {
                    reject(err);
                });
        });
    }

    get importedRecordFieldNames() {
        return Object.values(this.objectMappings).map(
            ({ Imported_Record_Field_Name }) =>
                Imported_Record_Field_Name
        );
    }

    getObjectMappingWrapperByImportedFieldName(importedFieldName) {
        return Object.values(this.objectMappings)
            .find(({ Imported_Record_Field_Name }) =>
                Imported_Record_Field_Name === importedFieldName);
    }

}

const geFormServiceInstance = new GeFormService();

export default geFormServiceInstance;
