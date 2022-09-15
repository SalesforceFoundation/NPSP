import { LightningElement, track } from 'lwc';
import getGatewaysFromElevate from '@salesforce/apex/PS_GatewayManagement.getGatewaysFromElevate';
import GeGatewaySettings from 'c/geGatewaySettings';
import { fireEvent } from 'c/pubsubNoPageRef';
import { isNotEmpty } from 'c/utilCommon';

export default class GeGatewaySelectWidget extends LightningElement {
    @track isDisplayed = false;
    @track selectedGateway = null;
    @track gatewayOptions = [];
    @track preGatewayOptions = [];
    @track isACHEnabled = true;
    @track isACHDisabled = false;
    @track isCreditCardEnabled = true;
    @track isCreditCardDisabled = false;
    @track isGatewaySelectionLoading = true;
    @track isGatewayLoadingMessage = 'Retrieving Elevate Gateway information. Please wait...';

    // TODO: This hard-coded value will be replaced after W-11564934 is complete...
    @track isGatewayAssignmentEnabled = true;

    _elevateGateways = null;
    _elevateGatewaysByUniqueKey = new Map();
    _firstDisplay = true;

    async connectedCallback() {
        this.resetAllSettingsToDefault;
        if (this.isGatewayAssignmentEnabled) {
            await this.getElevateGateways();
        }
        this.isGatewaySelectionLoading = false;
    }

    disconnectedCallback() {
        fireEvent(this, 'updateElevateSettings', null);
    }

    async getElevateGateways() {
        if (this._elevateGateways) {
            return true;
        }

        this._elevateGateways = JSON.parse(await getGatewaysFromElevate());

        // TODO: check for errors before creating map

        if (this._elevateGateways) {
            this.buildOptions();
        }

        return true;
    }

    buildOptions() {
        for (const gateway of this._elevateGateways) {
            this._elevateGatewaysByUniqueKey.set(gateway.uniqueKey, gateway);
            let optionLabel = gateway.isDefault ? gateway.alias + ' (Default)' : gateway.alias;
            this.gatewayOptions.push({label: optionLabel, value: gateway.uniqueKey});
        }
        this.gatewayOptions = this.gatewayOptions.sort((a, b) => a.label >= b.label ? 1 : -1);
    }

    toggleSelectGatewayControls() {
        if (this.isDisplayed) {
            this.isDisplayed = false;
        }
        else {
            this.isDisplayed = true;
            this.restoreSavedSettings();
        }
    }

    restoreSavedSettings() {
        if (!this._firstDisplay) {
            return;
        }

        let elevateSettings = GeGatewaySettings.getElevateSettings();
        if (isNotEmpty(elevateSettings)) {
            this.selectedGateway = elevateSettings.uniqueKey;
            this.isACHEnabled = elevateSettings.isACHEnabled;
            this.isCreditCardEnabled = elevateSettings.isCreditCardEnabled;

            this.updateDisabledPaymentTypes();

            this._firstDisplay = false;
        }
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

    updateElevateSettings() {
        let elevateSettings = {
            uniqueKey: this.selectedGateway,
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

    get isGatewayLoadingMessage() {
        return this.isGatewayLoadingMessage;
    }
}