export function removeFieldsNotInObjectInfo(dataImportRecord) {
    const diFields = Object.keys(this.dataImportObjectInfo.data.fields);
    for (const key of Object.keys(dataImportRecord)) {
        if (!diFields.includes(key)) {
            delete dataImportRecord[key];
        }
    }
    return dataImportRecord;
}

export function flatten(obj) {
    let flatObj = {};
    for (const [key, value] of Object.entries(obj)) {
        if (value !== null && value !== undefined && value.hasOwnProperty('value')) {
            flatObj[key] = value.value;
        } else {
            flatObj[key] = value;
        }
    }
    return flatObj;
}