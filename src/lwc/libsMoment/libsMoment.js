/* eslint-disable consistent-return */
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import CUMULUS_STATIC_RESOURCES from '@salesforce/resourceUrl/CumulusStaticResources';

class LibsMoment {
    isInitialized = false;
    moment;

    init = (context) => {
        if (this.isInitialized) {
            return;
        }
        this.isInitialized = true;

        return new Promise((resolve, reject) => {
            loadScript(context, CUMULUS_STATIC_RESOURCES + '/moment/moment.min.js')
                .then(() => {
                    this.moment = moment;
                    resolve();
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error loading static resource',
                            message: error.message,
                            variant: 'error',
                        }),
                    );
                    reject();
                });
        });
    }
}

export default new LibsMoment();