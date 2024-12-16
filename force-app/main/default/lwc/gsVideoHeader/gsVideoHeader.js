import { LightningElement } from 'lwc';
import CumulusStaticResources from '@salesforce/resourceUrl/CumulusStaticResources';
import gsVideoHeaderTitle from '@salesforce/label/c.gsVideoHeaderTitle';
import gsVideoLength from '@salesforce/label/c.gsVideoHeaderLength';
import opensInNewLink from '@salesforce/label/c.opensInNewLink'

const gsAssets = CumulusStaticResources + '/gsAssets';

export default class gsVideoHeader extends LightningElement {

    labels = {
        opensInNewLink,
    }

    backgroundUrl = gsAssets + '/Get_started_header.svg';
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

    get ariaLabel() {
        return `${gsVideoHeaderTitle} ${this.labels.opensInNewLink}` ;
    }

    get length() {
        return gsVideoLength;
    }
}