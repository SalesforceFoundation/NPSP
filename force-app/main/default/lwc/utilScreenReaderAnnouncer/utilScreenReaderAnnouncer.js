import { api, LightningElement } from 'lwc';

export default class UtilScreenReaderAnnouncer extends LightningElement {
    @api priority = 'polite';

    @api
    announce(message) {
        this.template.querySelector('div[data-id="liveregion"]').innerHTML = message;
    }
}