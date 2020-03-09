import { LightningElement, api } from 'lwc';
import GeLabelService from 'c/geLabelService';

export default class geTemplateBuilderWidget extends LightningElement {
    @api title;
    @api body;
    @api developerName;

    get uiTitle() {
        return GeLabelService.format(GeLabelService.CUSTOM_LABELS.geBodyWidgetFields, [this.title]);
    }

    get isAllocations() {
        return this.developerName === 'geFormWidgetAllocation';
    }

    get isTokenizeCard() {
        return this.developerName === 'geFormWidgetTokenizeCard';
    }
}