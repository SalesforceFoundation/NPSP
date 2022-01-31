import { LightningElement, api } from 'lwc';
import { isEmpty } from 'c/utilCommon';

import commonCancel from '@salesforce/label/c.commonCancel';
import geAddSchedule from '@salesforce/label/c.geAddSchedule';
import geUpdateSchedule from '@salesforce/label/c.geUpdateSchedule';

export default class GeModalRecurringDonation extends LightningElement {
    @api schedule;
    @api cancelCallback;
    @api createRecurrenceCallback;

    labels = {
        commonCancel,
    };

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
        const isValid = this.scheduleComponent.isValid();

        if (isValid) {
            const scheduleData = this.scheduleComponent.returnValues();
            this.createRecurrenceCallback(scheduleData);
        }
    }

    handleCancel() {
        this.cancelCallback();
    }
}
