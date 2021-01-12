import { LightningElement } from 'lwc';
import Resources from '@salesforce/resourceUrl/CumulusStaticResources'
import gseuTrailheadText from '@salesforce/label/c.gseuTrailheadText'
import gseuExploreTrailheadButton from '@salesforce/label/c.gseuExploreTrailheadButton'
export default class EuTrailhead extends LightningElement {
    /**
     * Url of the image shown in the component
     */
    imgUrl = Resources + '/gsAssets/trailheadComponent/trailheadLogo.svg';

    /**
     * Object to reference the labels
     */
    labels = {
        gseuTrailheadText,
        gseuExploreTrailheadButton
    }

    /**
     * Handles the click in the button. 
     * It opens an url(https://sforce.co/2MyeNE9) in a new tab.
     */
    handleClick() {
        window.open("https://sforce.co/2MyeNE9");
    }
}