import { LightningElement, track } from 'lwc';
import getGatewaysFromElevate from '@salesforce/apex/PS_GatewayManagement.getGatewaysFromElevate';
import encryptGatewayId from '@salesforce/apex/PS_GatewayManagement.encryptGatewayId';
import decryptGatewayId from '@salesforce/apex/PS_GatewayManagement.decryptGatewayId';
import isGatewayAssignmentEnabled from '@salesforce/apex/PS_GatewayManagement.isGatewayAssignmentEnabled';
import getDefaultTemplateId from '@salesforce/apex/PS_GatewayManagement.getDefaultTemplateId';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import GeGatewaySettings from 'c/geGatewaySettings';
import { fireEvent } from 'c/pubsubNoPageRef';
import { isNotEmpty } from 'c/utilCommon';

export default class GeGatewaySelectWidget extends LightningElement {
    @track isExpanded = false;
    @track selectedGateway = null;
    @track gatewayOptions = [];
    @track preGatewayOptions = [];
    @track isACHEnabled = true;
    @track isACHDisabled = false;
    @track isCreditCardEnabled = true;
    @track isCreditCardDisabled = false;
    @track isReady = false;
    @track isDefaultTemplate = false;
    @track isGatewayAssignmentEnabled = false;

    CUSTOM_LABELS = { messageLoading };

    _elevateGateways = null;
    _elevateGatewaysByUniqueKey = new Map();
    _firstDisplay = true;

    async connectedCallback() {
        if (GeGatewaySettings.getTemplateRecordId() === await getDefaultTemplateId()) {
            this.isDefaultTemplate = true;
            this.isReady = true;
            return;
        }

        this.resetAllSettingsToDefault;
        this.isGatewayAssignmentEnabled = await isGatewayAssignmentEnabled();
        if (this.isGatewayAssignmentEnabled) {
            await this.getElevateGateways();
        }

        this.isReady = true;
    }

    disconnectedCallback() {
        fireEvent(this, 'updateElevateSettings', null);
    }

    async getElevateGateways() {
        if (this._elevateGateways) {
            return;
        }

        this._elevateGateways = JSON.parse(await getGatewaysFromElevate());

        if (this._elevateGateways && !this._elevateGateways.errors) {
            this.buildOptions();
        } else {
            this.handleErrors();
        }
    }

    handleErrors(errorMessage) {
        console.log('boom!!!');
    }

    buildOptions() {
        for (const gateway of this._elevateGateways) {
            this._elevateGatewaysByUniqueKey.set(gateway.id, gateway);
            let optionLabel = gateway.isDefault ? gateway.gatewayName + ' (Default)' : gateway.gatewayName;
            this.gatewayOptions.push({label: optionLabel, value: gateway.id});
        }
        this.gatewayOptions = this.gatewayOptions.sort((a, b) => a.label >= b.label ? 1 : -1);
    }

    async toggleSelectGatewayControls() {
        if (this.isExpanded) {
            this.isExpanded = false;
        }
        else {
            await this.restoreSavedSettings();
            this.isExpanded = true;
        }
    }

    async restoreSavedSettings() {
        if (!this._firstDisplay) {
            return;
        }

        let elevateSettings = GeGatewaySettings.getElevateSettings();
        if (isNotEmpty(elevateSettings)) {
            let savedGatewayId = await decryptGatewayId({encryptedGatewayId: elevateSettings.uniqueKey});

            if (this.isValidSavedGatewayId(savedGatewayId)) {
                this.selectedGateway = savedGatewayId;
                this.isACHEnabled = elevateSettings.isACHEnabled;
                this.isCreditCardEnabled = elevateSettings.isCreditCardEnabled;
                this.updateDisabledPaymentTypes();
            }
            else {
                this.handleErrors('invalid saved gateway');
            }
        }
        this._firstDisplay = false;
    }

    isValidSavedGatewayId(savedGatewayId) {
        return !!this._elevateGatewaysByUniqueKey.get(savedGatewayId);
    }

    handleGatewaySelectionChange(event) {
        this.selectedGateway = event.detail.value;
        this.resetDefaultPaymentTypes();
        this.updateACHSettings();
        this.updateCreditCardSettings();
        this.updateElevateSettings();
    }

    updateDisabledPaymentTypes() {
        if (!this.isACHAvailableFor(this.selectedGateway)) {
            this.isACHDisabled = true;
        }
        if (!this.isCreditCardAvailableFor(this.selectedGateway)) {
            this.isCreditCardDisabled = true;
        }
    }

    handleACHChange(event) {
        this.isACHEnabled = event.target.checked;
        this.handlePaymentTypeChange();
    }

    handleCreditCardChange(event) {
        this.isCreditCardEnabled = event.target.checked;
        this.handlePaymentTypeChange();
    }

    handlePaymentTypeChange() {
        this.updateElevateSettings();
    }

    updateACHSettings() {
        if (!this.isACHAvailableFor(this.selectedGateway)) {
            this.isACHEnabled = false;
            this.isACHDisabled = true;
        }
        else {
            this.isACHDisabled = false;
        }
    }

    updateCreditCardSettings() {
        if (!this.isCreditCardAvailableFor(this.selectedGateway)) {
            this.isACHEnabled = false;
            this.isCreditCardDisabled = true;
        }
        else {
            this.isCreditCardDisabled = false;
        }
    }

    isACHAvailableFor(gateway) {
        if (this._elevateGatewaysByUniqueKey.get(gateway).isACHEnabled) {
            return true;
        }
        return false;
    }

    isCreditCardAvailableFor(gateway) {
        if (this._elevateGatewaysByUniqueKey.get(gateway).isCreditCardEnabled) {
            return true;
        }
        return false;
    }

    resetDefaultPaymentTypes() {
        this.isACHEnabled = true;
        this.isCreditCardEnabled = true;
    }

    resetAllSettingsToDefault() {
        this._elevateGateways = null;
        this._elevateGatewaysByUniqueKey = new Map();
        this.selectedGateway = null;
        this.gatewayOptions = [];
        this.isACHEnabled = true;
        this.isACHDisabled = false;
        this.isCreditCardEnabled = true;
        this.isCreditCardDisabled = false;
    }

    async updateElevateSettings() {
        let elevateSettings = {
            uniqueKey: await encryptGatewayId( {gatewayId: this.selectedGateway}),
            isACHEnabled: this.isACHEnabled,
            isCreditCardEnabled: this.isCreditCardEnabled
        }
        fireEvent(this, 'updateElevateSettings', elevateSettings);
    }

    get isACHEnabled() {
        return this.isACHEnabled;
    }

    get selectedGateway() {
        return this.selectedGateway;
    }

    get isCreditCardEnabled() {
        return this.isCreditCardEnabled;
    }
}