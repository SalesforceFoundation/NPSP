import { getAllocationWidgetDevNameStubs } from 'c/geFormWidgetAllocation';
import { getLikeMatchByKey } from 'c/utilCommon';

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
    * @description Getter for the geFormWidgetAllocation object and field mapping
    * developer name stubs.
    */
    get allocationWidgetStubs() {
        return getAllocationWidgetDevNameStubs(
            this.objectMappingByDevName,
            this.fieldMappingByDevName);
    }

    /*******************************************************************************
    * @description Getter all widget definitions
    * (org specific object and field mapping developer names)
    */
    get definitions() {
        return {
            geFormWidgetAllocation: this.getMappingDeveloperNames(
                this.allocationWidgetStubs.objectMappingDeveloperNameStubs,
                this.allocationWidgetStubs.fieldMappingDeveloperNameStubs),
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