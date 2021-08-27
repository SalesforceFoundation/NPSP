import { LightningElement, api } from 'lwc';

export default class Rd2ChangeEntry extends LightningElement {
    @api entryItem;

    get badgeClass() {
        if(this.entryItem.changeType === 'Upgrade') {
            return 'slds-theme_success';
        } else if(this.entryItem.changeType === 'Downgrade') {
            return 'slds-theme_error';
        }
        return '';
    }

    get hasStatusChange() {
        return this.entryItem.statusReason != null;
    }
}