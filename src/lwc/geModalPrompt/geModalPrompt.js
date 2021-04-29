import { LightningElement, api } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import { isEmpty } from 'c/utilCommon';

export default class geModalPrompt extends LightningElement {

    @api variant = '';
    @api title;
    @api message;
    @api button1Text;
    @api button1Action;
    @api button2Text;
    @api button2Action;

    handleButton1Click() {
        if (!isEmpty(this.button1Action)) {
            this.button1Action();
        } else {
            this.handleCloseModal();
        }
    }

    handleButton2Click() {
        if (!isEmpty(this.button2Action)) {
            this.button2Action();
        } else {
            this.handleCloseModal();
        }
    }    

    handleCloseModal() {
        fireEvent(this.pageRef, 'geModalCloseEvent', {});
    }

    get titleSectionComputedClass() {

        let allowedVariants = ['warning', 'shade', 'inverse', 'alt-inverse', 
            'success', 'info', 'error', 'offline', 'default'];

        let baseClass = ['slds-box', 'slds-theme_alert-texture', 'slds-box_extension'];

        if (isEmpty(this.variant) || !allowedVariants.includes(this.variant)) {
            baseClass.push('slds-theme_default');
            return baseClass.join(' ');
        }

        baseClass.push('slds-theme_'+ this.variant);
        return baseClass.join(' ');
    }
}