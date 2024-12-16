import { LightningElement } from 'lwc';
import gsVideoHeaderTitle from '@salesforce/label/c.gsVideoHeaderTitle';
import CumulusStaticResources from '@salesforce/resourceUrl/CumulusStaticResources';

export default class GseuHeader extends LightningElement {
    backgroundUrl = CumulusStaticResources + '/gsAssets/gseuHeader/GetStarted.svg';
    /**
    * Returns an Image URL to display in UI
    * @return      the image at the specified URL
    * @see         URL
    */
    get imgSrc() {
        return `background-image:url(${this.backgroundUrl});
                background-size: cover;
                background-repeat: no-repeat;
                background-position: center center;
                padding-top: 42%`;
    }

    get title() {
        return gsVideoHeaderTitle;
    }

}