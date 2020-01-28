import { getAllocationWidgetDefinition } from 'c/geFormWidgetAllocation';
import { getLikeMatchByKey } from 'c/utilCommon';

class GeWidgetService {
    objectMappingByDevName = null;
    fieldMappingByDevName = null;

    init(objectMappingByDevName, fieldMappingByDevName) {
        this.objectMappingByDevName = objectMappingByDevName;
        this.fieldMappingByDevName = fieldMappingByDevName;
    }

    get allocationWidgetStubs() {
        return getAllocationWidgetDefinition(
            this.objectMappingByDevName,
            this.fieldMappingByDevName);
    }

    get WidgetDefinitions() {
        return {
            geFormWidgetAllocation: this.getMappingDeveloperNames(
                this.allocationWidgetStubs.objectMappingDeveloperNameStubs,
                this.allocationWidgetStubs.fieldMappingDeveloperNameStubs),
        }
    }

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