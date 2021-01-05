import { LightningElement } from 'lwc';
import Resources from '@salesforce/resourceUrl/CumulusStaticResources'
import euTrailheadText from '@salesforce/label/c.euTrailheadText'
import euExploreTrailheadButton from '@salesforce/label/c.euExploreTrailheadButton'
export default class EuTrailhead extends LightningElement {
    
    imgUrl = Resources + '/euAssets/trailheadLogo.png';

    labels = {
        euTrailheadText,
        euExploreTrailheadButton
    }

    handleClick() {
        window.open("https://sforce.co/2MyeNE9");
    }
}