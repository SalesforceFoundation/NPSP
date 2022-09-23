import { registerListener } from 'c/pubsubNoPageRef';

class GeGatewaySettings {

    elevateSettings = {};
    templateRecordId = null;

    setElevateSettings(initialSettings, templateRecordId) {
        this.elevateSettings = initialSettings;
        this.templateRecordId = templateRecordId;
        registerListener('updateElevateSettings', this.settings, this);
    }

    getElevateSettings() {
        return this.elevateSettings;
    }

    getTemplateRecordId() {
        return this.templateRecordId;
    }

    settings(event) {
        this.elevateSettings = event;
    }
}

export default new GeGatewaySettings();