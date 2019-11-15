import getFieldMappingSet from '@salesforce/apex/BDI_MappingServiceAdvanced.getFieldMappingSet';
import getNamespaceWrapper from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getNamespaceWrapper';
import { handleError } from 'c/utilTemplateBuilder';

class GeTemplateBuilderService {
    fieldMappingByDevName = null;
    fieldMappingsByObjMappingDevName = null;
    objectMappingByDevName = null;
    namespaceWrapper = null;

    init = async (fieldMappingSetName, refresh) => {
        if (this.fieldMappingByDevName === null ||
            this.fieldMappingsByObjMappingDevName === null ||
            this.objectMappingByDevName === null ||
            refresh === true) {
            await this.handleGetFieldMappingSet(fieldMappingSetName);
        }

        if (this.namespaceWrapper === null || refresh === true) {
            await this.handleGetNamespaceWrapper();
        }
    }

    /*******************************************************************************
    * @description Method makes an imperative apex call and populates various
    * field and object maps using the class BDI_MappingServiceAdvanced.
    *
    * @param {string} fieldMappingSetName: Name of a Data_Import_Field_Mapping_Set__mdt
    * record.
    *
    * @return {object} promise: Promise from the imperative apex call
    * getFieldMappingSet.
    */
    handleGetFieldMappingSet = (fieldMappingSetName) => {
        return new Promise((resolve, reject) => {
            getFieldMappingSet({ fieldMappingSetName: fieldMappingSetName })
                .then(data => {
                    this.fieldMappingByDevName = data.fieldMappingByDevName;
                    this.objectMappingByDevName = data.objectMappingByDevName;

                    this.addWidgetsPlaceholder(this.fieldMappingByDevName, this.objectMappingByDevName);
                    this.fieldMappingsByObjMappingDevName =
                        this.populateFieldMappingsByObjMappingDevName(
                            this.fieldMappingByDevName,
                            this.objectMappingByDevName);
                    resolve(data);
                })
                .catch(error => {
                    handleError(error);
                    reject(error);
                });
        });
    }

    /*******************************************************************************
    * @description Method makes an imperative apex call and populates the
    * namespaceWrapper property.
    *
    * @return {object} promise: Promise from the imperative apex call
    * getNamespaceWrapper.
    */
    handleGetNamespaceWrapper = () => {
        return new Promise((resolve, reject) => {
            getNamespaceWrapper()
                .then(data => {
                    this.namespaceWrapper = data;
                    resolve(data);
                })
                .catch(error => {
                    handleError(error);
                    reject(error);
                })
        });
    }

    // TODO: Replace or delete later when actual widgets are in place.
    /*******************************************************************************
    * @description Placeholder method for mocking widgets in the UI.
    *
    * @param {object} fieldMappingByDevName: Map of field mappings.
    * @param {object} objectMappingByDevName: Map of object mappings.
    */
    addWidgetsPlaceholder = (fieldMappingByDevName, objectMappingByDevName) => {
        fieldMappingByDevName['geCreditCardWidget'] = {
            DeveloperName: 'geCreditCardWidget',
            MasterLabel: 'Credit Card',
            Target_Object_Mapping_Dev_Name: 'Widgets',
            Target_Field_Label: 'Credit Card',
            Required: 'No',
            Element_Type: 'widget',
        }

        objectMappingByDevName['Widgets'] = {
            DeveloperName: 'Widgets',
            MasterLabel: 'Widgets'
        }
    }

    /*******************************************************************************
    * @description Method takes in a map of field mappings and object mappings and
    * returns a map of field mappings by object mapping developer names.
    *
    * @param {object} fieldMappingByDevName: Map of field mappings.
    * @param {object} objectMappingByDevName: Map of object mappings.
    *
    * @return {object} fieldMappingsByObjMappingDevName: Map of field mappings by
    * object mapping developer names.
    */
    populateFieldMappingsByObjMappingDevName = (fieldMappingByDevName, objectMappingByDevName) => {
        let fieldMappingsByObjMappingDevName = {};
        let fieldMappings = Object.values(fieldMappingByDevName);

        for (let objectName in objectMappingByDevName) {
            if (objectMappingByDevName.hasOwnProperty(objectName)) {
                let fieldMappingChildren = fieldMappings.filter(mapping => {
                    return mapping.Target_Object_Mapping_Dev_Name === objectName
                });

                fieldMappingsByObjMappingDevName[objectName] = fieldMappingChildren;
            }
        }

        return fieldMappingsByObjMappingDevName;
    }
}

export default new GeTemplateBuilderService();