import { registerListener } from 'c/pubsubNoPageRef';

class GeGatewaySettings {

    elevateSettings = {};

    setElevateSettings(initialSettings) {
        this.elevateSettings = initialSettings;
        registerListener('updateElevateSettings', this.handleSettingsUpdate, this);
    }

    getElevateSettings() {
        return this.elevateSettings;
    }

    handleSettingsUpdate(event) {
        this.elevateSettings = event;
    }
}

export default new GeGatewaySettings();