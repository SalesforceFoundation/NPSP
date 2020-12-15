import GeFormService from 'c/geFormService';
import { isNotEmpty } from 'c/utilCommon';
import { isTrueFalsePicklist } from 'c/utilTemplateBuilder';

export default class GeFormElementHelper {
    element;

    constructor(element) {
        this.element = element;
    }

    get fieldMapping() {
        return GeFormService.getFieldMappingWrapper(this.formElementName);
    }

    get targetObjectMappingDevName() {
        if (isNotEmpty(this.fieldMapping)) {
            return this.fieldMapping.Target_Object_Mapping_Dev_Name;
        }
    }

    get formElementName() {
        return this.element.componentName ? this.element.componentName : this.element.dataImportFieldMappingDevNames[0];
    }

    get objectMapping() {
        return GeFormService.getObjectMapping(this.targetObjectMappingDevName);
    }

    get hasMappingInformation() {
        return isNotEmpty(this.objectMapping) && isNotEmpty(this.fieldMapping);
    }

    get isWidget() {
        return !!this.element.componentName;
    }

    isRenderable() {
        if (this.isWidget) {
            // always render widgets
            return true;
        } else if (isNotEmpty(this.fieldMapping)) {
            // the mapping record for this field is valid when it exists and
            // the source and target fields are describable
            return this.hasMappingInformation && this.fieldMapping.isDescribable;
        }
        return false;
    }

    isTrueFalsePicklist() {
        return isTrueFalsePicklist(this.fieldMapping);
    }
}