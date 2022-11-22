import getRenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import getFormRenderWrapper from '@salesforce/apex/GE_GiftEntryController.getFormRenderWrapper';
import getAllocationSettings from '@salesforce/apex/GE_GiftEntryController.getAllocationsSettings';
import getFieldMappings from '@salesforce/apex/GE_GiftEntryController.getFieldMappings';
import getOrgDomainInfo from '@salesforce/apex/UTIL_AuraEnabledCommon.getOrgDomainInfo';

import { handleError } from 'c/utilTemplateBuilder';
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
    'DOUBLE': 'decimal',
    'DECIMAL': 'decimal'
};

class GeFormService {

    fieldMappings;
    objectMappings;
    fieldTargetMappings;
    formTemplate;
    donationFieldTemplateLabel;

    getOrgDomain = async () => {
        try {
            return await getOrgDomainInfo();
        } catch(error) {
            handleError(error);
        }
    }

    /**
     * Retrieve the default form render wrapper.
     * @returns {Promise<GE_GiftEntryController.RenderWrapper>}
     */
    getFormTemplate() {
        return new Promise((resolve, reject) => {
            getRenderWrapper({})
                .then((result) => {
                    this.readFieldMappings(result.fieldMappingSetWrapper);
                    this.formTemplate = result.formTemplate;
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

    getFieldMappings() {
        return new Promise((resolve, reject) => {
           getFieldMappings()
               .then(result => {
                   this.readFieldMappings(result);
                   resolve(result);
               })
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
     * Get a object info object by dev name
     * @param objectMappingDevName
     * @returns {BDI_ObjectMapping}
     */
    getObjectMapping(objectMappingDevName) {
        return this.objectMappings[objectMappingDevName];
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
            if (isNotEmpty(fieldElement)) {
                // return custom label from the form template layout
                return fieldElement.customLabel;
            } 
        }

        return OPPORTUNITY_AMOUNT.fieldApiName;        
    }

    getFormRenderWrapper(templateId) {
        return new Promise((resolve, reject) => {
            getFormRenderWrapper({ templateId: templateId })
                .then(renderWrapper => {
                    this.readFieldMappings(renderWrapper.fieldMappingSetWrapper)
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
        return this.objectMappings && Object.values(this.objectMappings)
            .map(
                ({Imported_Record_Field_Name}) => Imported_Record_Field_Name
            );
    }

    readFieldMappings(fieldMappingSetWrapper) {
        this.fieldMappings = fieldMappingSetWrapper.fieldMappingByDevName;
        this.objectMappings = fieldMappingSetWrapper.objectMappingByDevName;
        this.fieldTargetMappings = fieldMappingSetWrapper.fieldMappingByTargetFieldName;
    }

    fieldMappingsForImportedRecordFieldName(importedRecordFieldName) {
        return this.fieldMappings && Object.values(this.fieldMappings)
            .filter(
                fieldMapping =>
                    fieldMapping.Target_Object_Mapping_Dev_Name ===
                    this.objectMappingWrapperFor(importedRecordFieldName).DeveloperName
            );
    }

    objectMappingWrapperFor(importedFieldName) {
        return this.objectMappings && Object.values(this.objectMappings)
            .find(({Imported_Record_Field_Name}) =>
                Imported_Record_Field_Name === importedFieldName);
    }

    fieldMappingsForObjectMappingDevName(objectMappingDevName) {
        return this.fieldMappings && Object.values(this.fieldMappings)
            .filter(fieldMapping =>
                fieldMapping.Target_Object_Mapping_Dev_Name === objectMappingDevName);
    }

    getFieldLabelBySourceFromTemplate(sourceFieldApiName) {
        const mapping = this.fieldMappingForSourceField(sourceFieldApiName);
        return this.getFieldLabelByDevNameFromTemplate(mapping.DeveloperName);
    }

    getFieldLabelByDevNameFromTemplate(developerName) {
        const element = this.findElementByDeveloperName(developerName);
        return element.customLabel;
    }

    findElementByDeveloperName(developerName) {
        const allElements = this.formTemplate.layout.sections.flatMap(s => s.elements);
        return allElements.find(element => {
            return element.dataImportFieldMappingDevNames
                && element.dataImportFieldMappingDevNames.includes(developerName);
        });
    }

    fieldMappingForSourceField(sourceFieldApiName) {
        return this.fieldMappings && Object.values(this.fieldMappings)
            .find(
                fieldMapping => fieldMapping.Source_Field_API_Name === sourceFieldApiName
            );
    }

    isSourceFieldInTemplate(sourceFieldApiName) {
        const mapping = this.fieldMappingForSourceField(sourceFieldApiName);
        return !!this.findElementByDeveloperName(mapping.DeveloperName);
    }

}

const geFormServiceInstance = new GeFormService();

export default geFormServiceInstance;
