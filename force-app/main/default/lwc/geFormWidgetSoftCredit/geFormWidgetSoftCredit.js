import { LightningElement, api, track } from 'lwc';
import GeLabelService from 'c/geLabelService';

import { deepClone, isNotEmpty } from 'c/utilCommon';
import { fireEvent } from 'c/pubsubNoPageRef';

export default class GeFormWidgetSoftCredit extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api giftInView;
    @api element;
    @track alertBanner = {};

    @track rowList = [];

    connectedCallback() {
        console.log('Gift In View: ', deepClone(this.giftInView));
    }

    handleAddRow() {
        console.log('handleAddRow');
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

    reset() {
        // handle reset
    }

    validate() {
        // validate
    }

    get hasAlert() {
        return false;
    }

    get alertIcon() {
        if (isNotEmpty(this.alertBanner.level)) {
            const warningIcon = 'utility:warning';
            const errorIcon = 'utility:error';
            switch(this.alertBanner.level) {
                case 'error':
                    return errorIcon;
                case 'warning':
                    return warningIcon;
                default:
                    return errorIcon;
            }
        }
    }

    get alertClass() {
        if (isNotEmpty(this.alertBanner.level)) {
            const errorClass = 'error';
            const warningClass = 'warning';

            switch(this.alertBanner.level) {
                case errorClass:
                    return errorClass;
                case warningClass:
                    return warningClass;
                default:
                    return errorClass;
            }
        }
    }

    get qaLocatorAddNewSoftCredit() {
        return `button ${this.CUSTOM_LABELS.geAddNewAllocation}`;
    }
}