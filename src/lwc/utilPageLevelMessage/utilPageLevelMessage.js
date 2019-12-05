import { LightningElement, api } from 'lwc';

const SUCCESS = 'success';
const WARNING = 'warning';
const ERROR = 'error';
const INFO = 'info';
const THEME_SUCCESS = 'slds-theme_success';
const THEME_WARNING = 'slds-theme_warning';
const THEME_ERROR = 'slds-theme_error';
const THEME_INFO = 'slds-theme_info';
const TEXT_ERROR = 'slds-text-color_error';

export default class utilPageLevelMessage extends LightningElement {
    @api title;
    @api subtitle;
    @api errors;
    @api iconName;
    @api iconSize;
    @api iconVariant;
    @api iconDescription;
    @api variant;

    get titleText() {
        return this.title ? this.title : 'Review the errors on this page.';
    }

    get subtitleText() {
        return this.subtitle ? this.subtitle : '';
    }

    get hasIconName() {
        return this.iconName ? true : false;
    }

    get assistiveText() {
        switch (this.variant) {
            case SUCCESS:
                return SUCCESS;
            case WARNING:
                return WARNING;
            case ERROR:
                return ERROR;
            default:
                return INFO;
        }
    }

    get notificationClass() {
        let classNames = 'slds-notify slds-notify_extension slds-notify_toast ';
        switch (this.variant) {
            case SUCCESS:
                classNames += THEME_SUCCESS;
                break;
            case WARNING:
                classNames += THEME_WARNING;
                break;
            case ERROR:
                classNames += THEME_ERROR;
                break;
            default:
                classNames += THEME_INFO;
                break;
        }
        return classNames;
    }

    get subtitleClass() {
        let classNames = 'slds-p-top_x-small ';
        if (this.variant === ERROR) {
            classNames += TEXT_ERROR;
        }
        return classNames;
    }
}
