import { registerListener } from 'c/pubsubNoPageRef';

class GeGatewaySettings {

    elevateSettings = {};
    templateRecordId = null;

    setElevateSettings(initialSettings, templateRecordId) {
        this.elevateSettings = initialSettings;
        this.templateRecordId = templateRecordId;
        registerListener('updateElevateSettings', this.handleSettingsUpdate, this);
    }

    getElevateSettings() {
        return this.elevateSettings;
    }

    getTemplateRecordId() {
        return this.templateRecordId;
    }

    handleSettingsUpdate(event) {
        this.elevateSettings = event;
    }
}

export default new GeGatewaySettings();