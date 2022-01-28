import { LightningElement, api } from 'lwc';

export default class GeRecurringGiftInfo extends LightningElement {
    @api schedule;

    get scheduleAsString() {
        return JSON.stringify(this.schedule);
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