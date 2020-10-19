import gsChecklistExploreNPSPTitle from '@salesforce/label/c.gsChecklistExploreNPSPTitle';
import gsChecklistExploreNPSPDesc from '@salesforce/label/c.gsChecklistExploreNPSPDesc';
import gsChecklistMakeItYourDesc from '@salesforce/label/c.gsChecklistMakeItYourDesc';
import gsChecklistMakeItYourTitle from '@salesforce/label/c.gsChecklistMakeItYourTitle';
import gsChecklistOnboardUsersTitle from '@salesforce/label/c.gsChecklistOnboardUsersTitle';
import gsChecklistOnboardUsersDesc from '@salesforce/label/c.gsChecklistOnboardUsersDesc';
import gsChecklistItemSetupContactTitle from '@salesforce/label/c.gsChecklistItemSetupContactTitle';
import gsChecklistItemSetupContactDesc from '@salesforce/label/c.gsChecklistItemSetupContactDesc';
import gsChecklistItemSetupContactPriBtnLabel from '@salesforce/label/c.gsChecklistItemSetupContactPriBtnLabel';
import gsChecklistItemSetupContactSecBtnLabel from '@salesforce/label/c.gsChecklistItemSetupContactSecBtnLabel';
import gsChecklistItemStayTrackTitle from '@salesforce/label/c.gsChecklistItemStayTrackTitle';
import gsChecklistItemStayTrackDesc from '@salesforce/label/c.gsChecklistItemStayTrackDesc';
import gsChecklistItemStayTrackLinkLabel from '@salesforce/label/c.gsChecklistItemStayTrackLinkLabel';
import gsChecklistItemStayTrackPriBtnLabel from '@salesforce/label/c.gsChecklistItemStayTrackPriBtnLabel';

const mapValue = {
    gsChecklistExploreNPSPTitle,
    gsChecklistExploreNPSPDesc,
    gsChecklistMakeItYourDesc,
    gsChecklistMakeItYourTitle,
    gsChecklistOnboardUsersTitle,
    gsChecklistOnboardUsersDesc,
    gsChecklistItemSetupContactTitle,
    gsChecklistItemSetupContactDesc,
    gsChecklistItemSetupContactPriBtnLabel,
    gsChecklistItemSetupContactSecBtnLabel,
    gsChecklistItemStayTrackTitle,
    gsChecklistItemStayTrackDesc,
    gsChecklistItemStayTrackLinkLabel,
    gsChecklistItemStayTrackPriBtnLabel,
}


/**
*    
*/
export default function translate(label) {
    return mapValue[label] != undefined ? mapValue[label] : label;
}