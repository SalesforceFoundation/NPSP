import getMappingServiceWrappers from '@salesforce/apex/GE_TemplateBuilderCtrl.getMappingService';

class GeTemplateBuilderService {
    fieldMappingByDevName = null;
    fieldMappingsByObjMappingDevName = null;
    objectMappingByDevName = null;

    init = (fieldMappingSetName) => {
        return new Promise((resolve, reject) => {
            getMappingServiceWrappers({ fieldMappingSetName: fieldMappingSetName })
                .then(data => {
                    this.fieldMappingByDevName = data.fieldMappingByDevName;
                    this.fieldMappingsByObjMappingDevName = data.fieldMappingsByObjMappingDevName;
                    this.objectMappingByDevName = data.objectMappingByDevName;
                    resolve(data);
                })
                .catch(error => {
                    console.log(error);
                    reject(error);
                });
        });
    }
}

export default new GeTemplateBuilderService();