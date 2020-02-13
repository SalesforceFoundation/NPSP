import getFieldMappingSet from '@salesforce/apex/BDI_MappingServiceAdvanced.getFieldMappingSet';
import getNamespaceWrapper from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getNamespaceWrapper';
import { handleError } from 'c/utilTemplateBuilder';
import { mutable } from 'c/utilCommon';
import GeWidgetService from 'c/geWidgetService';
import labelGeHeaderFieldBundles from '@salesforce/label/c.geHeaderFieldBundles';

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
            getFieldMappingSet({ fieldMappingSetName: fieldMappingSetName, includeUtilityFields: true })
                .then(data => {
                    // data is immutable after Promise resolution.  Since the
                    // addWidgetsPlaceholder adds properties to these objects, using
                    // mutable (JSON.parse/stringify) to store as new objects rather than
                    // pointing to the data props.
                    this.fieldMappingByDevName =
                        mutable(data.fieldMappingByDevName);
                    this.objectMappingByDevName =
                        mutable(data.objectMappingByDevName);
                    this.fieldMappingsByObjMappingDevName =
                        mutable(data.fieldMappingsByObjMappingDevName);

                    this.addWidgetsPlaceholder(this.fieldMappingByDevName,
                        this.objectMappingByDevName,
                        this.fieldMappingsByObjMappingDevName);

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

    /*******************************************************************************
    * @description Method checks if running in non-namespaced or non-npsp namespaced
    * environment, this method will strip off the NPSP prefix of a field or object
    * name and replace it with the current namespace of the UTIL_Namespace if
    * appropriate.
    *
    * @return {string} newName: String aligned with the current environment namespace
    */
    alignSchemaNSWithEnvironment = (name) => {
        if (this.namespaceWrapper && this.namespaceWrapper.currentNamespace) {
            const namespacePrefix = `${this.namespaceWrapper.currentNamespace}__`;
            let newName = name.replace('npsp__', '');

            return newName.includes(namespacePrefix) ? newName : `${namespacePrefix}${newName}`;
        }

        return name;
    }

    /*******************************************************************************
    * @description Placeholder method for mocking widgets in the UI.
    *
    * @param {object} fieldMappingByDevName: Map of field mappings.
    * @param {object} objectMappingByDevName: Map of object mappings.
    */
    addWidgetsPlaceholder = (fieldMappingByDevName, objectMappingByDevName, fieldMappingsByObjMappingDevName) => {

        GeWidgetService.init(objectMappingByDevName, fieldMappingByDevName);
        const allocationWidgetDefinition = GeWidgetService.definitions.geFormWidgetAllocation;

        fieldMappingByDevName.geFormWidgetAllocation = {
            DeveloperName: 'geFormWidgetAllocation',
            MasterLabel: 'Allocations',
            Target_Object_Mapping_Dev_Name: 'Widgets',
            Target_Field_Label: 'Allocations',
            Required: 'No',
            Element_Type: 'widget',
            Widget_Object_Mapping_Developer_Name: allocationWidgetDefinition.objectMappingDeveloperName,
            Widget_Field_Mapping_Developer_Names: allocationWidgetDefinition.fieldMappingDeveloperNames
        };

        objectMappingByDevName.Widgets = {
            DeveloperName: 'Widgets',
            MasterLabel: labelGeHeaderFieldBundles
        };

        fieldMappingsByObjMappingDevName.Widgets = [
            fieldMappingByDevName.geFormWidgetAllocation
        ]
    }
}

export default new GeTemplateBuilderService();
