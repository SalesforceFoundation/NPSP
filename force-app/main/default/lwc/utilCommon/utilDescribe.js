import { nonePicklistOption, createPicklistOption } from './utilCommon';

export default class UtilDescribe {
    _objectDescribeInfo;

    setDescribe(objectDescribeInfo) {
        this._objectDescribeInfo = objectDescribeInfo;
    }

    getFieldDescribe(fieldApiName) {
        if(this._objectDescribeInfo) {
            return this._objectDescribeInfo.fields[fieldApiName];
        }
    }

    get accessibleRecordTypes() {
        if (!this._objectDescribeInfo) return [];
        const allRecordTypes = Object.values(this._objectDescribeInfo.recordTypeInfos);
        return allRecordTypes.filter(recordType => recordType.available && !recordType.master);
    }

    defaultRecordTypeId() {
        return this._objectDescribeInfo && this._objectDescribeInfo.defaultRecordTypeId;
    }

    recordTypeNameFor(recordTypeId) {
        return this._objectDescribeInfo &&
            Object.values(this._objectDescribeInfo.recordTypeInfos)
                .find(rtInfo => rtInfo.recordTypeId === recordTypeId)
                .name;
    }

    recordTypeIdFor(recordTypeName) {
        if (recordTypeName === null) {
            return null;
        }

        const rtInfo = this._objectDescribeInfo &&
            Object.values(this._objectDescribeInfo.recordTypeInfos)
                .find(rtInfo => rtInfo.name === recordTypeName);

        return rtInfo && rtInfo.recordTypeId;
    }

    getPicklistOptionsForRecordTypeIds() {
        if (!this.accessibleRecordTypes ||
            this.accessibleRecordTypes.length <= 0) {
            return [nonePicklistOption()];
        }

        return this.accessibleRecordTypes.map(recordType => {
            return createPicklistOption(recordType.name,
                recordType.recordTypeId);
        });
    }
}