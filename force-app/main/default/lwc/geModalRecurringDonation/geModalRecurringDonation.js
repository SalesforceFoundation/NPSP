import { LightningElement, api } from 'lwc';
import { isEmpty } from 'c/utilCommon';

import commonCancel from '@salesforce/label/c.commonCancel';
import geAddSchedule from '@salesforce/label/c.geAddSchedule';
import geUpdateSchedule from '@salesforce/label/c.geUpdateSchedule';

export default class GeModalRecurringDonation extends LightningElement {
    @api schedule;
    @api cancelCallback;
    @api createRecurrenceCallback;

    labels = {};

    connectedCallback() {
        this.labels = {
            commonCancel
        }
    }

    get titleSectionComputedClass() {
        let allowedVariants = ['warning', 'shade', 'inverse', 'alt-inverse', 
            'success', 'info', 'error', 'offline', 'default'];
        let baseClass = ['slds-box', 'slds-box_extension'];

        if (isEmpty(this.variant) || !allowedVariants.includes(this.variant)) {
            baseClass.push('slds-theme_default');
            return baseClass.join(' ');
        }

        baseClass.push('slds-theme_'+ this.variant);
        return baseClass.join(' ');
    }

    get isUpdatingSchedule() {
        return !isEmpty(this.schedule);
    }

    get applyScheduleButton() {
        return this.isUpdatingSchedule ? geUpdateSchedule : geAddSchedule;
    }

    get scheduleComponent() {
        return this.template.querySelectorAll("[data-id=\"scheduleComponent\"]")[0];
    }

    handleAddSchedule() {
        const scheduleData = this.scheduleComponent.returnValues();
        this.createRecurrenceCallback(scheduleData);
    }

    handleCancel() {
        this.cancelCallback();
    }
}
