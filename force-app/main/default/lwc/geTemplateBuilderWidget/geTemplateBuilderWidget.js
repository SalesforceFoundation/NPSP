import { LightningElement, api } from 'lwc';
import GeLabelService from 'c/geLabelService';

export default class geTemplateBuilderWidget extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api title;
    @api body;
    @api developerName;

    get uiTitle() {
        return GeLabelService.format(this.CUSTOM_LABELS.geBodyWidgetFields, [this.title]);
    }

    get isAllocations() {
        return this.developerName === 'geFormWidgetAllocation';
    }

    get isTokenizeCard() {
        return this.developerName === 'geFormWidgetTokenizeCard';
    }
}