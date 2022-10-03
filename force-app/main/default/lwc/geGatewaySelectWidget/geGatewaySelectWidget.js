import { LightningElement, track, api } from 'lwc';
import getGatewaysFromElevate from '@salesforce/apex/GE_GiftEntryController.getGatewaysFromElevate';
import encryptGatewayId from '@salesforce/apex/GE_GiftEntryController.encryptGatewayId';
import decryptGatewayId from '@salesforce/apex/GE_GiftEntryController.decryptGatewayId';
import getGatewayAssignmentSettings from '@salesforce/apex/GE_GiftEntryController.getGatewayAssignmentSettings';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import psACH from '@salesforce/label/c.psACH';
import psElevateConnectionTimeout from '@salesforce/label/c.psElevateConnectionTimeout';
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
import { isEmpty, showToast } from 'c/utilCommon';

const TEMPLATE_CSS_CLASS = 'template-top';
const GIFT_ENTRY_CSS_CLASS = 'gift-entry-top';

export default class GeGatewaySelectWidget extends LightningElement {
    @track isExpanded = false;
    @track selectedGateway = null;
    @track gatewayOptions = [];
    @track isACHEnabled = true;
    @track isACHDisabled = false;
    @track isCreditCardEnabled = true;
    @track isCreditCardDisabled = false;
    @track isLoading = true;
    @track isDefaultTemplate = false;
    @track isGatewayAssignmentEnabled = false;
    @track isGatewaySelectionDisabled = false;

    @api parentIsGE = false;

    CUSTOM_LABELS = Object.freeze({
        messageLoading,
        psACH,
        psElevateConnectionTimeout,
        psGatewayDefault,
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
    _defaultTemplateId = null;
    _defaultGatewayId = null;

    async init() {
        try {
            let gatewayAssignmentSettings = JSON.parse(await getGatewayAssignmentSettings());

            this._defaultTemplateId = gatewayAssignmentSettings.defaultTemplateId;
            this.isGatewayAssignmentEnabled = gatewayAssignmentSettings.gatewayAssignmentEnabled;
            this._defaultGatewayId = gatewayAssignmentSettings.defaultGatewayId;
        }
        catch (e) {
            this._firstDisplay = false;
            this.handleErrors();
        }

        if (this._defaultTemplateId === GeGatewaySettings.getTemplateRecordId()) {
            this.isDefaultTemplate = true;
            this.isLoading = false;
            return;
        }

        this.resetAllSettingsToDefault;
    }

    async connectedCallback() {
        await this.init();

        if (this.isGatewayAssignmentEnabled) {
            await this.getElevateGateways();
        }
        else {
            this.isLoading = false;
        }

        if (this.parentIsGE) {
            await this.restoreSavedSettings();
        }
    }

    disconnectedCallback() {
        fireEvent(this, 'updateElevateSettings', null);
    }

    async getElevateGateways() {
        if (this._elevateGateways) {
            return;
        }

        try {
            this._elevateGateways = JSON.parse(await getGatewaysFromElevate());
        }
        catch (e) {
            this._firstDisplay = false;
            this.handleErrors();
        }

        if (this._elevateGateways && this._elevateGateways.length > 0 && !(this._elevateGateways.errors)) {
            this.buildOptions();
            this.isLoading = false;
        } else {
            this.handleErrors();
        }
    }

    buildOptions() {
        for (const gateway of this._elevateGateways) {
            this._elevateGatewaysByUniqueKey.set(gateway.id, gateway);
            this.gatewayOptions.push({label: gateway.gatewayName, value: gateway.id});
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
        if (this.isGatewayAssignmentEnabled) {
            await this.handleInitialGatewaySelection(elevateSettings);
        }
        else {
            this.handleInitialPaymentMethodSelections(elevateSettings);
        }

        if (this.parentIsGE) {
            this.disableAllControls();
        }

        this._firstDisplay = false;
    }

    async handleInitialGatewaySelection(elevateSettings) {
        if (isEmpty(elevateSettings) || isEmpty(elevateSettings.uniqueKey)) {
            await this.selectDefaultGateway();
        } else {
            await this.selectSavedGateway(elevateSettings);
        }
    }

    async selectDefaultGateway() {
        this.selectedGateway = this._defaultGatewayId;
        this.updateACHSettings();
        this.updateCreditCardSettings();
        this.updateDisabledPaymentTypes();
    }

    async selectSavedGateway(elevateSettings) {
        let savedGatewayId = await decryptGatewayId({encryptedGatewayId: elevateSettings.uniqueKey});

        if (this.isValidSavedGatewayId(savedGatewayId)) {
            this.selectedGateway = savedGatewayId;
            this.isACHEnabled = elevateSettings.isACHEnabled;
            this.isCreditCardEnabled = elevateSettings.isCreditCardEnabled;
            this.updateDisabledPaymentTypes();
        } else {
            this._savedGatewayNotFound = true;
            this.handleErrors();
        }
    }

    handleInitialPaymentMethodSelections(elevateSettings) {
        if (elevateSettings) {
            this.isACHEnabled = elevateSettings.isACHEnabled;
            this.isCreditCardEnabled = elevateSettings.isCreditCardEnabled;
        }
    }

    handleErrors() {
        let formattedErrorMessage;
        let details = null;

        if (this._savedGatewayNotFound) {
            formattedErrorMessage = this.CUSTOM_LABELS.psGatewayNotValid;
        }
        else if (!this._elevateGateways || this._elevateGateways.length === 0) {
            formattedErrorMessage = this.CUSTOM_LABELS.psGatewaysNotFound;
        }
        else if (this._elevateGateways.errors.includes('timed out')) {
            formattedErrorMessage = this.CUSTOM_LABELS.psElevateConnectionTimeout;
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
        this.updateElevateSettings();
    }

    handleCreditCardChange(event) {
        this.isCreditCardEnabled = event.target.checked;
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
            this.isCreditCardEnabled = false;
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
        this.isGatewaySelectionDisabled = false;
    }

    async updateElevateSettings() {
        let elevateSettings = {
            uniqueKey: this.isGatewayAssignmentEnabled ?
                await encryptGatewayId( {gatewayId: this.selectedGateway}) : null,
            isACHEnabled: this.isACHEnabled,
            isCreditCardEnabled: this.isCreditCardEnabled
        }
        fireEvent(this, 'updateElevateSettings', elevateSettings);
    }

    disableAllControls() {
        this.isGatewaySelectionDisabled = true;
        this.isCreditCardDisabled = true;
        this.isACHDisabled = true;
    }

    get hideInGiftEntryBatch() {
        if (this.parentIsGE) {
            if (GeGatewaySettings.getIsGiftEntryBatch() && this.isGatewayAssignmentEnabled) {
                return false;
            }
            return true;
        }
        return false;
    }

    get cssClassPrefix() {
        return this.parentIsGE ? GIFT_ENTRY_CSS_CLASS : TEMPLATE_CSS_CLASS;
    }
}