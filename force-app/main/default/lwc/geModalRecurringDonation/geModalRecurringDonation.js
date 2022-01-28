import { LightningElement, api } from 'lwc';

export default class GeModalRecurringDonation extends LightningElement {
    @api schedule;
    @api cancelCallback;
    @api createRecurrenceCallback;

    get titleSectionComputedClass() {
        let allowedVariants = ['warning', 'shade', 'inverse', 'alt-inverse', 
            'success', 'info', 'error', 'offline', 'default'];
        let baseClass = ['slds-box', 'slds-box_extension'];

        if (isEmpty(this.variant) || !allowedVariants.includes(this.variant)) {
            baseClass.push('slds-theme_default');
            return baseClass.join(' ');
        }

        baseClass.push('slds-theme_'+ this.variant);
        return baseClass.join(' ');
    }

    get scheduleComponent() {
        return this.template.querySelectorAll("[data-id=\"scheduleComponent\"]")[0];
    }

    handleCreateRecurrence() {
        const scheduleData = this.scheduleComponent.returnValues();
        this.createRecurrenceCallback(scheduleData);
    }

    handleCancel() {
        this.cancelCallback();
    }
}
