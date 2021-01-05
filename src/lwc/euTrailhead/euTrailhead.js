import { LightningElement } from 'lwc';
import Resources from '@salesforce/resourceUrl/CumulusStaticResources'
import euTrailheadText from '@salesforce/label/c.euTrailheadText'
import euExploreTrailheadButton from '@salesforce/label/c.euExploreTrailheadButton'
export default class EuTrailhead extends LightningElement {
    /**
     * Url of the image shown in the component
     */
    imgUrl = Resources + '/euAssets/trailheadLogo.png';

    /**
     * Object to reference the labels
     */
    labels = {
        euTrailheadText,
        euExploreTrailheadButton
    }

    /**
     * Handles the click in the button. 
     * It opens an url(https://sforce.co/2MyeNE9) in a new tab.
     */
    handleClick() {
        window.open("https://sforce.co/2MyeNE9");
    }
}