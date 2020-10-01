import { LightningElement } from 'lwc';
import CumulusStaticResources from '@salesforce/resourceUrl/CumulusStaticResources';

const gsAssets = CumulusStaticResources + '/gsAssets';

export default class gsVideoHeader extends LightningElement {

    /**
    * Returns an Image URL to display in UI
    * @return      the image at the specified URL
    * @see         URL
    */
    get imgSrc() {
        return gsAssets + '/Getting_started_header.svg';
    }
}