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
import { fireEvent, registerListener } from 'c/pubsubNoPageRef';
import { isEmpty, showToast } from 'c/utilCommon';

const PAYMENT_METHOD_MODE = 'PAYMENT';
const GATEWAY_MANAGEMENT_MODE = 'MANAGEMENT';

export default class GeGatewaySelectWidget extends LightningElement {
    @track isExpanded = false;
    @track selectedGateway = null;
    @track gatewayOptions = [];
    @track isACHEnabled = true;
    @track isACHUnavailable = false;
    @track isCreditCardEnabled = true;
    @track isCreditCardUnavailable = false;
    @track isLoading = true;
    @track isDefaultTemplate = false;
    @track isGatewayAssignmentEnabled = false;
    @track isGatewaySelectionDisabled = false;

    @api parentContext = '';

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
    _widgetMode;
    _initialSelectedGateway = null;

    async init() {
        try {
            const gatewayAssignmentSettings = JSON.parse(await getGatewayAssignmentSettings());

            this._defaultTemplateId = gatewayAssignmentSettings.defaultTemplateId;
            this.isGatewayAssignmentEnabled = gatewayAssignmentSettings.gatewayAssignmentEnabled;
            this._defaultGatewayId = gatewayAssignmentSettings.defaultGatewayId;
        }
        catch (error) {
            this._firstDisplay = false;
            this.handleErrors(error);
        }

        this.setWidgetMode();

        if (this.onGatewayManagementPage()) {
            this.handlePaymentGatewayCancel();
        }
        else {
            this.initWidgetSettings();
        }
    }

    initWidgetSettings() {
        if (this._defaultTemplateId === GeGatewaySettings.getTemplateRecordId()) {
            this.isDefaultTemplate = !this.onGatewayManagementPage();
            this.isLoading = false;
            return;
        }

        this.resetAllSettingsToDefault;
    }

    async connectedCallback() {
        await this.init();

        if (this.shouldShowGateways) {
            await this.getElevateGateways();
        }
        else {
            this.isLoading = false;
        }

        if (this.onGatewayManagementPage()) {
            registerListener('editGatewayManagement', this.enableGatewaySelection, this);
            registerListener('saveGatewayManagement', this.handlePaymentGatewaySave, this);
            registerListener('cancelGatewayManagement', this.handlePaymentGatewayCancel, this);
            await this.toggleSelectGatewayControls();
        }
    }

    disconnectedCallback() {
        fireEvent(this, 'updateElevateSettings', null);
    }

    setWidgetMode() {
        if (this.parentContext === GATEWAY_MANAGEMENT_MODE) {
            this._widgetMode = GATEWAY_MANAGEMENT_MODE;
        }

        else if (!this.isGatewayAssignmentEnabled) {
            this._widgetMode = PAYMENT_METHOD_MODE;
        }
    }

    async getElevateGateways() {
        if (this._elevateGateways) {
            return;
        }

        try {
            this._elevateGateways = JSON.parse(await getGatewaysFromElevate());
        }
        catch (error) {
            this._firstDisplay = false;
            this.handleErrors(error);

            return;
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

        if (!this.onGatewayManagementPage()) {
            this.addDefaultGatewayOption();
        }
    }

    addDefaultGatewayOption() {
        this._elevateGatewaysByUniqueKey.set(null, {
            gatewayName: this.CUSTOM_LABELS.psGatewayDefault,
            id: null,
            isACHEnabled: true,
            isCreditCardEnabled: true
        });
        this.gatewayOptions.splice(0, 0, {label: this.CUSTOM_LABELS.psGatewayDefault, value: null});
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

        if (!this.inPaymentMethodMode()) {
            await this.handleInitialGatewaySelection(GeGatewaySettings.getElevateSettings());
        }
        else {
            this.handleInitialPaymentMethodSelections(GeGatewaySettings.getElevateSettings());
        }

        if (this.onGatewayManagementPage()) {
            this.isExpanded = true;
            fireEvent(this, 'updateSelectedGateway', this.selectedGateway);
            registerListener('resetToInitialGateway', this.resetToInitialGateway, this);
        }

        this._firstDisplay = false;
    }

    async handleInitialGatewaySelection(elevateSettings) {
        if (isEmpty(elevateSettings) || this.onGatewayManagementPage()) {
            await this.selectDefaultGateway();
        } else {
            await this.selectSavedGateway(elevateSettings);
        }
        this._initialSelectedGateway = this.selectedGateway;
    }

    async selectDefaultGateway() {
        this.selectedGateway = this.onGatewayManagementPage() ? this._defaultGatewayId : null;
        if (!this.onGatewayManagementPage()) {
            this.updateACHSettings();
            this.updateCreditCardSettings();
            this.updateDisabledPaymentTypes();
        }
    }

    async selectSavedGateway(elevateSettings) {
        let savedGatewayId = await decryptGatewayId({encryptedGatewayId: elevateSettings.uniqueKey});

        if (this.isValidSavedGatewayId(savedGatewayId)) {
            this.selectedGateway = savedGatewayId;
            if (!this.onGatewayManagementPage()) {
                this.isACHEnabled = elevateSettings.isACHEnabled;
                this.isCreditCardEnabled = elevateSettings.isCreditCardEnabled;
                this.updateDisabledPaymentTypes();
            }
        } else {
            this._savedGatewayNotFound = true;
            this.handleErrors();
        }
    }

    handleInitialPaymentMethodSelections(elevateSettings) {
        if (!!elevateSettings) {
            this.isACHEnabled = elevateSettings.isACHEnabled;
            this.isCreditCardEnabled = elevateSettings.isCreditCardEnabled;
        }
    }

    handleErrors(error) {
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
        else if (!!error) {
            formattedErrorMessage = error;
        }
        else {
            formattedErrorMessage = this.CUSTOM_LABELS.psUnableToConnect;
            details = this._elevateGateways.errors.map((error) => error.message).join("\n ");
        }

        if (!this.onGatewayManagementPage()) {
            this.displayError(formattedErrorMessage, details);
        }
        else {
            this.isLoading = false;
            fireEvent(this, 'getElevateGatewaysError', formattedErrorMessage);
        }
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
            this.isACHUnavailable = true;
        }
        if (!this.isCreditCardAvailableFor(this.selectedGateway)) {
            this.isCreditCardUnavailable = true;
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
            this.isACHUnavailable = true;
        }
        else {
            this.isACHUnavailable = false;
        }
    }

    updateCreditCardSettings() {
        if (!this.isCreditCardAvailableFor(this.selectedGateway)) {
            this.isCreditCardEnabled = false;
            this.isCreditCardUnavailable = true;
        }
        else {
            this.isCreditCardUnavailable = false;
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
        this.isACHUnavailable = false;
        this.isCreditCardEnabled = true;
        this.isCreditCardUnavailable = false;
    }

    enableGatewaySelection() {
        this.isGatewaySelectionDisabled = false;
    }

    disableGatewaySelection() {
        this.isGatewaySelectionDisabled = true;
    }

    handlePaymentGatewaySave(event) {
        this._initialSelectedGateway = event;
        this.disableGatewaySelection();
    }

    handlePaymentGatewayCancel() {
        this.resetToInitialGateway();
        this.disableGatewaySelection();
    }

    async updateElevateSettings() {
        if (!this.onGatewayManagementPage()) {
            const elevateSettings = {
                uniqueKey: this.isGatewayAssignmentEnabled ?
                    await encryptGatewayId({gatewayId: this.selectedGateway}) : null,
                isACHEnabled: this.isACHEnabled,
                isCreditCardEnabled: this.isCreditCardEnabled
            };
            fireEvent(this, 'updateElevateSettings', elevateSettings);
        }
        else {
            fireEvent(this, 'updateSelectedGateway', this.selectedGateway);
        }
    }

    resetToInitialGateway() {
        this.selectedGateway = this._initialSelectedGateway;
    }

    onGatewayManagementPage() {
        return this._widgetMode === GATEWAY_MANAGEMENT_MODE;
    }

    inPaymentMethodMode() {
        return this._widgetMode === PAYMENT_METHOD_MODE;
    }

    get shouldShowGateways() {
        return !this.inPaymentMethodMode();
    }

    get shouldShowPaymentMethods() {
        return !this.onGatewayManagementPage();
    }

    get shouldShowExpandControls() {
        return !this.onGatewayManagementPage();
    }
}