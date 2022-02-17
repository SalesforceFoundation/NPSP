import { LightningElement, api, track } from 'lwc';
import { isEmpty } from 'c/utilCommon';

import { Rd2Service } from "c/rd2Service";

import commonCancel from '@salesforce/label/c.commonCancel';
import geAddSchedule from '@salesforce/label/c.geAddSchedule';
import geUpdateSchedule from '@salesforce/label/c.geUpdateSchedule';

export default class GeModalRecurringDonation extends LightningElement {
    @api schedule;
    @api cancelCallback;
    @api createRecurrenceCallback;

    rd2Service = new Rd2Service();
    @track rd2State = this.rd2Service.init();

    async connectedCallback() {
        this.rd2State = await this.rd2Service.loadInitialView();
    }

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
