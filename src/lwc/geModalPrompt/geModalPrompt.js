import { LightningElement, api } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';

export default class geModalPrompt extends LightningElement {

    @api severity;
    @api title;
    @api message;
    @api buttonText;

    handleCloseModal() {
        fireEvent(this.pageRef, 'geModalCloseEvent', {});
    }

    get titleSectionComputedClass() {
        let baseClass = ['slds-box', 'slds-theme_alert-texture', 'slds-box_extension'];

        if (this.severity === 'warning') {
            baseClass.push('slds-theme_warning');
        } else if (this.severity === 'shade') {
            baseClass.push('slds-theme_shade');
        } else if (this.severity === 'inverse') {
            baseClass.push('slds-theme_inverse');
        } else if (this.severity === 'alt-inverse') {
            baseClass.push('slds-theme_alt-inverse');
        } else if (this.severity === 'success') {
            baseClass.push('slds-theme_success');
        } else if (this.severity === 'info') {
            baseClass.push('slds-theme_info');
        } else if (this.severity === 'error') {
            baseClass.push('slds-theme_error');
        } else if (this.severity === 'offline') {
            baseClass.push('slds-theme_offline');                                                
        } else {
            baseClass.push('slds-theme_default');
        }

        return baseClass.join(' ');
    }
}