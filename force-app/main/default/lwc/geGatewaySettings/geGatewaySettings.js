import { registerListener } from 'c/pubsubNoPageRef';
import decryptGatewayId from '@salesforce/apex/GE_GiftEntryController.decryptGatewayId';
import { showToast } from 'c/utilCommon';
import psGatewayNotValid from '@salesforce/label/c.psGatewayNotValid';

class GeGatewaySettings {

    elevateSettings = {};
    templateRecordId = null;
    decryptedGatewayId = null;
    isGiftEntryBatch = false;
    isGiftEntry = false;

    setElevateSettings(initialSettings, templateRecordId) {
        this.elevateSettings = initialSettings;
        this.templateRecordId = templateRecordId;
        registerListener('updateElevateSettings', this.settings, this);
    }

    initDecryptedElevateSettings(elevateSettings) {
        this.isGiftEntry = true;
        this.isGiftEntryBatch = true;
        this.elevateSettings = elevateSettings;
        if (this.elevateSettings?.uniqueKey) {
            this.decryptElevateGateway().then(error => {
                if (this.elevateSettings?.uniqueKey && !this.decryptedGatewayId) {
                    showToast(psGatewayNotValid, details, 'error', 'sticky');
                }
            });
        }
    }

    clearDecryptedElevateSettings() {
        this.isGiftEntry = true;
        this.isGiftEntryBatch = false;
        this.elevateSettings = {};
        this.decryptedGatewayId = null;
    }

    async decryptElevateGateway() {
        this.decryptedGatewayId = await decryptGatewayId({encryptedGatewayId: this.elevateSettings.uniqueKey});
    }

    getElevateSettings() {
        return this.elevateSettings;
    }

    getDecryptedGatewayId() {
        return this.decryptedGatewayId;
    }

    getIsGiftEntry() {
        return this.isGiftEntry;
    }

    getIsGiftEntryBatch() {
        return this.isGiftEntryBatch;
    }

    getTemplateRecordId() {
        return this.templateRecordId;
    }

    settings(event) {
        this.elevateSettings = event;
    }
}

export default new GeGatewaySettings();