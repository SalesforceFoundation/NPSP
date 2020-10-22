import gsChecklistExploreNPSPTitle from '@salesforce/label/c.gsChecklistExploreNPSPTitle';
import gsChecklistExploreNPSPDesc from '@salesforce/label/c.gsChecklistExploreNPSPDesc';
import gsChecklistMakeItYourDesc from '@salesforce/label/c.gsChecklistMakeItYourDesc';
import gsChecklistMakeItYourTitle from '@salesforce/label/c.gsChecklistMakeItYourTitle';
import gsChecklistOnboardUsersTitle from '@salesforce/label/c.gsChecklistOnboardUsersTitle';
import gsChecklistOnboardUsersDesc from '@salesforce/label/c.gsChecklistOnboardUsersDesc';
import gsChecklistItemSetupContactTitle from '@salesforce/label/c.gsChecklistItemSetupContactTitle';
import gsChecklistItemSetupContactDesc from '@salesforce/label/c.gsChecklistItemSetupContactDesc';
import gsChecklistItemSetupContactLinkLabel from '@salesforce/label/c.gsChecklistItemSetupContactLinkLabel';
import gsChecklistItemSetupContactPriBtnLabel from '@salesforce/label/c.gsChecklistItemSetupContactPriBtnLabel';
import gsChecklistItemSetupContactSecBtnLabel from '@salesforce/label/c.gsChecklistItemSetupContactSecBtnLabel';
import gsChecklistItemStayTrackTitle from '@salesforce/label/c.gsChecklistItemStayTrackTitle';
import gsChecklistItemStayTrackDesc from '@salesforce/label/c.gsChecklistItemStayTrackDesc';
import gsChecklistItemStayTrackLinkLabel from '@salesforce/label/c.gsChecklistItemStayTrackLinkLabel';
import gsChecklistItemStayTrackPriBtnLabel from '@salesforce/label/c.gsChecklistItemStayTrackPriBtnLabel';
import gsChecklistItemCreateDonationTitle from '@salesforce/label/c.gsChecklistItemCreateDonationTitle';
import gsChecklistItemCreateDonationDesc from '@salesforce/label/c.gsChecklistItemCreateDonationDesc';
import gsChecklistItemCreateDonationLinkLabel from '@salesforce/label/c.gsChecklistItemCreateDonationLinkLabel';
import gsChecklistItemCreateDonationPriBtnLabel from '@salesforce/label/c.gsChecklistItemCreateDonationPriBtnLabel'; 
import gsChecklistItemExtraOneMinuteVideo from '@salesforce/label/c.gsChecklistItemExtraOneMinuteVideo';

const mapValue = {
    gsChecklistExploreNPSPTitle,
    gsChecklistExploreNPSPDesc,
    gsChecklistMakeItYourDesc,
    gsChecklistMakeItYourTitle,
    gsChecklistOnboardUsersTitle,
    gsChecklistOnboardUsersDesc,
    gsChecklistItemSetupContactTitle,
    gsChecklistItemSetupContactDesc,
    gsChecklistItemSetupContactLinkLabel,
    gsChecklistItemSetupContactPriBtnLabel,
    gsChecklistItemSetupContactSecBtnLabel,
    gsChecklistItemStayTrackTitle,
    gsChecklistItemStayTrackDesc,
    gsChecklistItemStayTrackLinkLabel,
    gsChecklistItemStayTrackPriBtnLabel,
    gsChecklistItemCreateDonationTitle,
    gsChecklistItemCreateDonationDesc,
    gsChecklistItemCreateDonationLinkLabel,
    gsChecklistItemCreateDonationPriBtnLabel,
    gsChecklistItemExtraOneMinuteVideo,
}


/**
*  @description This function translate the string using mapValue for that
*/
export default function translate(label) {
    return mapValue[label] != undefined ? mapValue[label] : label;
}