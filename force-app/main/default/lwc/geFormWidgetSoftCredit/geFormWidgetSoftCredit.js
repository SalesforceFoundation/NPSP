import { LightningElement, api, track } from 'lwc';
import GeLabelService from 'c/geLabelService';
import geSoftCreditsWarning from '@salesforce/label/c.geSoftCreditsWarning';

import { fireEvent } from 'c/pubsubNoPageRef';
import { isEmptyObject } from 'c/utilCommon';

const NET_NEW_SOFT_CREDITS_LIMIT = 250;

export default class GeFormWidgetSoftCredit extends LightningElement {

    CUSTOM_LABELS = {
        ...GeLabelService.CUSTOM_LABELS,
        geSoftCreditsWarning
    }

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

    get softCredits() {
        if (this.giftInView?.softCredits) {
            return JSON.parse(this.giftInView.softCredits);
        }
        return [];
    }

    get processedSoftCredits() {
        if (this.giftInView?.processedSoftCredits) {
            return JSON.parse(this.giftInView.processedSoftCredits);
        }
        return [];
    }

    get isBelowLimit() {
        return this.softCredits.length < NET_NEW_SOFT_CREDITS_LIMIT;
    }

    get qaLocatorAddNewSoftCredit() {
        return `button ${this.CUSTOM_LABELS.geAddNewAllocation}`;
    }

    get giftInViewHasSchedule() {
        return !isEmptyObject(this.giftInView?.schedule);
    }
}