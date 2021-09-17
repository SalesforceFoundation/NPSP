import { LightningElement, api, track } from 'lwc';
import GeLabelService from 'c/geLabelService';

import { fireEvent } from 'c/pubsubNoPageRef';

const NET_NEW_SOFT_CREDITS_LIMIT = 250;

export default class GeFormWidgetSoftCredit extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api giftInView;
    @track alertBanner = {};

    handleAddRow() {
        fireEvent(this, 'softcreditwidgetchange', { action: 'addSoftCredit' });
    }

    handleRemove(event) {
        fireEvent(this, 'softcreditwidgetchange', {
            action: 'removeSoftCredit',
            detail: {
                key: event.detail.rowIndex
            }
        });
    }

    get isBelowLimit() {
        return this.giftInView.softCredits.length < NET_NEW_SOFT_CREDITS_LIMIT;
    }

    get qaLocatorAddNewSoftCredit() {
        return `button ${this.CUSTOM_LABELS.geAddNewAllocation}`;
    }
}