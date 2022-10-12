import { registerListener } from 'c/pubsubNoPageRef';
import decryptGatewayId from '@salesforce/apex/GE_GiftEntryController.decryptGatewayId';
import { showToast } from 'c/utilCommon';
import psGatewayNotValid from '@salesforce/label/c.psGatewayNotValid';
import getGatewayAssignmentSettings from '@salesforce/apex/GE_GiftEntryController.getGatewayAssignmentSettings';

class GeGatewaySettings {

    elevateSettings = {};
    templateRecordId = null;
    decryptedGatewayId = null;
    isGiftEntryBatch = false;

    setElevateSettings(initialSettings, templateRecordId) {
        this.isGiftEntryBatch = false;
        this.elevateSettings = initialSettings;
        this.templateRecordId = templateRecordId;
        registerListener('updateElevateSettings', this.settings, this);
    }

    initDecryptedElevateSettings(elevateSettings) {
        this.isGiftEntryBatch = true;
        this.elevateSettings = elevateSettings;

        if (this.elevateSettings?.uniqueKey) {
            getGatewayAssignmentSettings()
                .then(settingsJson => {
                    const gatewayAssignmentSettings = JSON.parse(settingsJson);
                    return gatewayAssignmentSettings?.gatewayAssignmentEnabled;
                })
                .then(shouldDecrypt => {
                    if (shouldDecrypt) {
                        this.decryptElevateGateway();
                    }
                })
                .catch((error) => {
                    this.handleError(psGatewayNotValid, error);
                });
        }
    }

    handleError(message, error) {
        showToast(message, error, 'error', 'sticky');
    }

    clearDecryptedElevateSettings() {
        this.isGiftEntryBatch = false;
        this.elevateSettings = {};
        this.decryptedGatewayId = null;
    }

    async decryptElevateGateway() {
        this.decryptedGatewayId = await decryptGatewayId({encryptedGatewayId: this.elevateSettings.uniqueKey});

        if (this.elevateSettings?.uniqueKey && !this.decryptedGatewayId) {
            this.handleError(psGatewayNotValid);
        }
    }

    isValidElevatePaymentMethod(paymentMethod) {

        if (!this.getElevateSettings()) {
            return true;
        } else if (this.getElevateSettings().isACHEnabled && this.getElevateSettings().isCreditCardEnabled) {
            return true;
        } else if (this.getElevateSettings().isCreditCardEnabled && paymentMethod === 'Credit Card') {
            return true;
        } else if (this.getElevateSettings().isACHEnabled && paymentMethod === 'ACH') {
            return true;
        }

        return false;
    }

    getElevateSettings() {
        return this.elevateSettings;
    }

    getDecryptedGatewayId() {
        return this.decryptedGatewayId;
    }

    getTemplateRecordId() {
        return this.templateRecordId;
    }

    settings(event) {
        this.elevateSettings = event;
    }
}

export default new GeGatewaySettings();