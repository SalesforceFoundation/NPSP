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

    getFormTemplate() {
        return new Promise((resolve, reject) => {
            getRenderWrapper()
                .then((result) => {
                    console.log(JSON.parse(JSON.stringify(result)));
                    this.fieldMappings = result.fieldMappingSetWrapper.fieldMappingByDevName;
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

    getFieldInfo(fieldName) {
        return this.fieldMappings[fieldName];
    }
}



const getInputTypeFromDataType = dataType => {
    return inputTypeByDescribeType[dataType];
};

const geFormServiceInstance = new GeFormService();

export default geFormServiceInstance;