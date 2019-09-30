import { LightningElement, api } from 'lwc';

export default class UtilPageHeader extends LightningElement {
    @api pageHeaderFor;

    _isBGETemplateBuilderHeader;
    _isBatchGiftEntryHeader;

    getCurrentPageHeader() {
        switch(this.pageHeaderFor) {
            case 'bgeTemplateBuilder':
                this._isBGETemplateBuilderHeader = true;
                break;
            case 'bgeGiftEntry':
                this._isBatchGiftEntryHeader = true;
                break;
            default:
        }
        return undefined;
    }

    connectedCallback() {
        this.getCurrentPageHeader();
    }
}