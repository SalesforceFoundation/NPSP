import { LightningElement, api } from 'lwc';

export default class GeRecurringGiftInfo extends LightningElement {
    @api schedule;

    get scheduleAsString() {
        return JSON.stringify(this.schedule);
    }

    handleEdit() {
        const customEvent = new CustomEvent('editrecurrence', {});
        this.dispatchEvent(customEvent);
    }

    handleRemoveRecurrence() {
        const customEvent = new CustomEvent('removerecurrence', {});
        this.dispatchEvent(customEvent);
    }
}