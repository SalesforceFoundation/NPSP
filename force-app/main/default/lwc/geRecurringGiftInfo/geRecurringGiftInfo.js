import { LightningElement, api } from 'lwc';

import commonEdit from '@salesforce/label/c.commonEdit';
import geRemoveSchedule from '@salesforce/label/c.geRemoveSchedule';

export default class GeRecurringGiftInfo extends LightningElement {
    @api schedule;

    labels = {}

    connectedCallback() {
        this.labels = {
            commonEdit,
            geRemoveSchedule,
        }
    }

    get scheduleAsString() {
        return `Recurring info: ${this.schedule.RecurringType__c}, ${this.schedule.StartDate__c}, ${this.schedule.npe03__Installment_Period__c}`;
    }

    handleEdit() {
        const customEvent = new CustomEvent('editschedule', {});
        this.dispatchEvent(customEvent);
    }

    handleRemoveSchedule() {
        const customEvent = new CustomEvent('removeschedule', {});
        this.dispatchEvent(customEvent);
    }
}
