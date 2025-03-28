import { api, LightningElement } from 'lwc'
import { isEmpty } from 'c/utilCommon';

const SUCCESS = 'success';
const WARNING = 'warning';
const ERROR = 'error';
const THEME_SUCCESS = 'slds-theme_success';
const THEME_WARNING = 'slds-theme_warning';
const THEME_ERROR = 'slds-theme_error';
const THEME_INFO = 'slds-theme_info';
const LEFT = 'left';
const RIGHT = 'right';
const floatLeftClass = 'slds-float_left';
const floatRightClass = 'slds-float_right';
const MODAL_CONTAINER_CLASS = 'slds-modal__container ';
const MODAL_SECTION_CLASS = 'slds-modal slds-fade-in-open slds-modal_prompt';


export default class utilPrompt extends LightningElement {

    @api headerTitle;
    @api promptMessage;
    @api variant;
    @api confirmButtonVariant;
    @api confirmButtonTitle;
    @api hasBackDrop;
    @api position;
    _themeClass = 'slds-modal__header ';

    get promptTheme() {
       switch (this.variant) {
         case SUCCESS:
            this._themeClass += THEME_SUCCESS;
            break;
         case WARNING:
            this._themeClass += THEME_WARNING;
            break;
         case ERROR:
            this._themeClass += THEME_ERROR;
            break;
         default:
            this._themeClass += THEME_INFO;
            break;
       }
       return this._themeClass;
    }

    get modalPosition () {
       switch (this.position) {
          case LEFT:
             return floatLeftClass;
          case RIGHT:
             return floatRightClass;
          default:
             return '';
       }
    }

    get sectionClass () {
       if (this.hasBackDrop) {
          return MODAL_SECTION_CLASS;
       }
       return '';
    }

    get modalClass () {
       if (isEmpty(this.position)) {
          return MODAL_CONTAINER_CLASS;
       } else {
         return MODAL_CONTAINER_CLASS + this.modalPosition;
       }
    }

    handleConfirmButtonClick (event) {
       this.dispatchEvent(new CustomEvent('confirm', event));
    }

}