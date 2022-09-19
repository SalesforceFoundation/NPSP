import { LightningElement, track } from 'lwc';
import getGatewaysFromElevate from '@salesforce/apex/GE_GiftEntryController.getGatewaysFromElevate';
import encryptGatewayId from '@salesforce/apex/GE_GiftEntryController.encryptGatewayId';
import decryptGatewayId from '@salesforce/apex/GE_GiftEntryController.decryptGatewayId';
import isGatewayAssignmentEnabled from '@salesforce/apex/GE_GiftEntryController.isGatewayAssignmentEnabled';
import getDefaultTemplateId from '@salesforce/apex/GE_GiftEntryController.getDefaultTemplateId';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import psACH from '@salesforce/label/c.psACH';
import psGatewayHelp from '@salesforce/label/c.psGatewayHelp';
import psGatewayDefault from '@salesforce/label/c.psGatewayDefault';
import psGatewaysNotFound from '@salesforce/label/c.psGatewaysNotFound';
import psGatewayNotValid from '@salesforce/label/c.psGatewayNotValid';
import psHideGatewaysAndMethods from '@salesforce/label/c.psHideGatewaysAndMethods';
import psHidePaymentMethods from '@salesforce/label/c.psHidePaymentMethods';
import psSelectPaymentGateway from '@salesforce/label/c.psSelectPaymentGateway';
import psSelectPaymentMethods from '@salesforce/label/c.psSelectPaymentMethods';
import psShowGatewaysAndMethods from '@salesforce/label/c.psShowGatewaysAndMethods';
import psShowPaymentMethods from '@salesforce/label/c.psShowPaymentMethods';
import psUnableToConnect from '@salesforce/label/c.psUnableToConnect';
import RD2_Credit_Card_Payment_Method_Label from '@salesforce/label/c.RD2_Credit_Card_Payment_Method_Label';
import GeGatewaySettings from 'c/geGatewaySettings';
import { fireEvent } from 'c/pubsubNoPageRef';
import { isNotEmpty, showToast } from 'c/utilCommon';

export default class GeGatewaySelectWidget extends LightningElement {
    @track isExpanded = false;
    @track selectedGateway = null;
    @track gatewayOptions = [];
    @track preGatewayOptions = [];
    @track isACHEnabled = true;
    @track isACHDisabled = false;
    @track isCreditCardEnabled = true;
    @track isCreditCardDisabled = false;
    @track isLoading = false;
    @track isDefaultTemplate = false;
    @track isGatewayAssignmentEnabled = false;

    CUSTOM_LABELS = Object.freeze({
        messageLoading,
        psACH,
        psGatewayDefault,
        psGatewayHelp,
        psGatewaysNotFound,
        psGatewayNotValid,
        psHideGatewaysAndMethods,
        psHidePaymentMethods,
        psSelectPaymentGateway,
        psSelectPaymentMethods,
        psShowGatewaysAndMethods,
        psShowPaymentMethods,
        psUnableToConnect,
        RD2_Credit_Card_Payment_Method_Label
    });

    _savedGatewayNotFound = false;
    _elevateGateways = null;
    _elevateGatewaysByUniqueKey = new Map();
    _firstDisplay = true;

    async connectedCallback() {
        if (GeGatewaySettings.getTemplateRecordId() === await getDefaultTemplateId()) {
            this.isDefaultTemplate = true;
            this.isLoading = true;
            return;
        }

        this.resetAllSettingsToDefault;
        this.isGatewayAssignmentEnabled = await isGatewayAssignmentEnabled();
        if (this.isGatewayAssignmentEnabled) {
            await this.getElevateGateways();
        }
        else {
            this.isLoading = true;
        }
    }

    disconnectedCallback() {
        fireEvent(this, 'updateElevateSettings', null);
    }

    async getElevateGateways() {
        if (this._elevateGateways) {
            return;
        }

        this._elevateGateways = JSON.parse(await getGatewaysFromElevate());

        if (this._elevateGateways && this._elevateGateways.length > 0 && !(this._elevateGateways.errors)) {
            this.buildOptions();
            this.isLoading = true;
        } else {
            this.handleErrors();
        }
    }

    buildOptions() {
        for (const gateway of this._elevateGateways) {
            this._elevateGatewaysByUniqueKey.set(gateway.id, gateway);
            let optionLabel = gateway.isDefault ? gateway.gatewayName +
                ' (' + this.CUSTOM_LABELS.psGatewayDefault + ')' : gateway.gatewayName;
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
                this._savedGatewayNotFound = true;
                this.handleErrors();
            }
        }
        this._firstDisplay = false;
    }

    handleErrors() {
        let formattedErrorMessage;
        let details;

        if (this._savedGatewayNotFound) {
            formattedErrorMessage = this.CUSTOM_LABELS.psGatewayNotValid;
        }
        else if (!this._elevateGateways || this._elevateGateways.length === 0) {
            formattedErrorMessage = this.CUSTOM_LABELS.psGatewaysNotFound;
        }
        else {
            formattedErrorMessage = this.CUSTOM_LABELS.psUnableToConnect;
            details = this._elevateGateways.errors.map((error) => error.message).join("\n ");
        }

        this.displayError(formattedErrorMessage, details);
    }

    displayError(message, details) {
        showToast(message, details, 'error', 'sticky');
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