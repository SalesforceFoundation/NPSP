import { getLikeMatchByKey } from 'c/utilCommon';

/*******************************************************************************
* @description Stubs of object and field mapping developer names. Used to collect
* the org specific mapping developer names for the widget geFormWidgetAllocation.
*/
const ALLOCATION_WIDGET_DEVELOPER_NAME_STUBS = {
    objectMappingDeveloperNameStubs: 'GAU_Allocation_1_',
    fieldMappingDeveloperNameStubs: [
        'GAU_Allocation_1_GAU_',
        'GAU_Allocation_1_Amount_',
        'GAU_Allocation_1_Percent_'
    ]
}

class GeWidgetService {
    objectMappingByDevName = null;
    fieldMappingByDevName = null;

    /*******************************************************************************
    * @description Initializes the GeWidgetService component with the migrated
    * object and field mappings.
    */
    init(objectMappingByDevName, fieldMappingByDevName) {
        this.objectMappingByDevName = objectMappingByDevName;
        this.fieldMappingByDevName = fieldMappingByDevName;
    }

    /*******************************************************************************
    * @description Getter all widget definitions
    * (org specific object and field mapping developer names)
    */
    get definitions() {
        return {
            geFormWidgetAllocation: this.getMappingDeveloperNames(
                ALLOCATION_WIDGET_DEVELOPER_NAME_STUBS.objectMappingDeveloperNameStubs,
                ALLOCATION_WIDGET_DEVELOPER_NAME_STUBS.fieldMappingDeveloperNameStubs),
            //geFormWidgetSomethingElse: this.getMappingDeveloperNames...
        }
    }

    /*******************************************************************************
    * @description Method collects the org specific developer name for the given
    * mappings and stubs.
    *
    * @param {string} objectMappingDeveloperNameStub: Stub of an object mapping
    * developer name e.g. 'GAU_Allocation_1_'
    * @param {list} fieldMappingNameStubs: List of field mapping developer name
    * stub e.g. ['General_Account_1_', 'Percent_', ...]
    */
    getMappingDeveloperNames(objectMappingDeveloperNameStub, fieldMappingNameStubs) {
        const objectMappingDeveloperName = getLikeMatchByKey(
            this.objectMappingByDevName,
            objectMappingDeveloperNameStub,
            true);

        const fieldMappingDeveloperNames = fieldMappingNameStubs.map(stub => {
            return getLikeMatchByKey(this.fieldMappingByDevName, stub, true);
        });

        return {
            objectMappingDeveloperName,
            fieldMappingDeveloperNames
        }
    }
}

export default new GeWidgetService();