import { nonePicklistOption, createPicklistOption } from './utilCommon';

export default class UtilDescribe {
    objectDescribeInfo;

    constructor(objectDescribeInfo) {
        this.objectDescribeInfo = objectDescribeInfo;
    }

    getFieldDescribe(fieldApiName) {
        return this.objectDescribeInfo.fields[fieldApiName];
    }

    get accessibleRecordTypes() {
        if (!this.objectDescribeInfo) return [];
        const allRecordTypes = Object.values(this.objectDescribeInfo.recordTypeInfos);
        return allRecordTypes.filter(recordType => recordType.available && !recordType.master);
    }

    defaultRecordTypeId() {
        return this.objectDescribeInfo && this.objectDescribeInfo.defaultRecordTypeId;
    }

    recordTypeNameFor(recordTypeId) {
        return this.objectDescribeInfo &&
            Object.values(this.objectDescribeInfo.recordTypeInfos)
                .find(rtInfo => rtInfo.recordTypeId === recordTypeId)
                .name;
    }

    recordTypeIdFor(recordTypeName) {
        if (recordTypeName === null) {
            return null;
        }

        const rtInfo = this.objectDescribeInfo &&
            Object.values(this.objectDescribeInfo.recordTypeInfos)
                .find(rtInfo => rtInfo.name === recordTypeName);

        return rtInfo && rtInfo.recordTypeId;
    }

    getPicklistOptionsForRecordTypeIds() {
        if (!this.accessibleRecordTypes ||
            this.accessibleRecordTypes.length <= 0) {
            return [nonePicklistOption()];
        }

        const recordTypeOptions = this.accessibleRecordTypes.map(recordType => {
            return createPicklistOption(recordType.name,
                recordType.recordTypeId);
        });

        return [nonePicklistOption(), ...recordTypeOptions];
    }
}