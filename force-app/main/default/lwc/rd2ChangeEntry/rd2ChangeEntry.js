import { LightningElement, api } from 'lwc';

export default class Rd2ChangeEntry extends LightningElement {
    @api changeEntry;

    get badgeClass() {
        if(this.changeEntry.changeType === 'Upgrade') {
            return 'slds-theme_success';
        } else if(this.changeEntry.changeType === 'Downgrade') {
            return 'slds-theme_error';
        }
        return '';
    }
}