import { LightningElement } from 'lwc';
import CumulusStaticResources from '@salesforce/resourceUrl/CumulusStaticResources';
import gsVideoHeaderTitle from '@salesforce/label/c.gsVideoHeaderTitle';
import gsVideoLength from '@salesforce/label/c.gsVideoHeaderLength';

const gsAssets = CumulusStaticResources + '/gsAssets';

export default class gsVideoHeader extends LightningElement {
    backgroundUrl = gsAssets + '/Get_started_header.svg';
    /**
    * Returns an Image URL to display in UI
    * @return      the image at the specified URL
    * @see         URL
    */
    get imgSrc() {
        return `background-image:url(${this.backgroundUrl});
                background-size: contain;
                background-repeat: no-repeat;
                width: 100%;
                height: 0;
                padding-top: 42%;
                position: relative`;
    }

    get title() {
        return gsVideoHeaderTitle;
    }

    get length() {
        return gsVideoLength;
    }
}