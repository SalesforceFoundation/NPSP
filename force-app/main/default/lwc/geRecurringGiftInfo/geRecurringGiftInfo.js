import { LightningElement, api } from 'lwc';

export default class GeRecurringGiftInfo extends LightningElement {
    @api schedule;

    get scheduleAsString() {
        return JSON.stringify(this.schedule);
    }
}