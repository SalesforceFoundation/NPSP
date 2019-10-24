import getRenderWrapper from '@salesforce/apex/GE_TemplateBuilderCtrl.retrieveDefaultFormRenderWrapper';

const inputTypeByDescribeType = {
    'CHECKBOX': 'checkbox',
    'CURRENCY': 'number',
    'DATE': 'date',
    'DATETIME': 'datetime-local',
    'EMAIL': 'email',
    'NUMBER': 'number',
    'STRING': 'text',
    'PHONE': 'tel',
    'TEXT': 'text',
    'TIME': 'time',
    'URL': 'url'
};

class GeFormService {

    fieldMappings;
    objectMappings;

    getFormTemplate() {
        return new Promise((resolve, reject) => {
            getRenderWrapper()
                .then((result) => {
                    console.log(JSON.parse(JSON.stringify(result)));
                    this.fieldMappings = result.fieldMappingSetWrapper.fieldMappingByDevName;
                    this.objectMappings = result.fieldMappingSetWrapper.objectMappingByDevName;
                    resolve(result);
                })
                .catch(error => {
                    console.error(JSON.stringify(error));
                });
        });
    };

    getInputTypeFromDataType(dataType) {
        return inputTypeByDescribeType[dataType];
    };

    getFieldInfo(fieldDevName) {
        return this.fieldMappings[fieldDevName];
    }

    getObjectInfo(objectDevName) {
        return this.objectMappings[objectDevName];
    }
}

const geFormServiceInstance = new GeFormService();

export default geFormServiceInstance;