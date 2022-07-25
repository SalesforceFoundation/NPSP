import { LightningElement, api } from 'lwc';
import gsResourcesTitle from '@salesforce/label/c.gsResourcesTitle';
import gsResourcesItemNonprofitCloudLabel from '@salesforce/label/c.gsResourcesItemNonprofitCloudLabel';
import gsResourcesItemNonprofitCloudLink from '@salesforce/label/c.gsResourcesItemNonprofitCloudLinkLabel';
import gsResourcesItemFundraisingLabel from '@salesforce/label/c.gsResourcesItemFundraisingLabel';
import gsResourcesItemFundraisingLink from '@salesforce/label/c.gsResourcesItemFundraisingLinkLabel';
import gsResourcesProgramManagementLabel from '@salesforce/label/c.gsResourcesItemProgramManagementLabel';
import gsResourcesProgramManagementLink from '@salesforce/label/c.gsResourcesItemProgramManagementLinkLabel';
import gsResourcesMarketingEngagementLabel from '@salesforce/label/c.gsResourcesItemMarketingEngagementLabel';
import gsResourcesMarketingEngagementLink from '@salesforce/label/c.gsResourcesItemMarketingEngagementLinkLabel';
import gsResourcesWebinarsLabel from '@salesforce/label/c.gsResourcesItemWebinarsLabel';
import gsResourcesWebinarsLink from '@salesforce/label/c.gsResourcesItemWebinarsLinkLabel';
import gsResourcesHubLabel from '@salesforce/label/c.gsResourcesItemHubLabel';
import gsResourcesHubLink from '@salesforce/label/c.gsResourcesItemHubLinkLabel';
import gsResourcesPartnersLabel from '@salesforce/label/c.gsResourcesItemPartnersLabel';
import gsResourcesPartnersLink from '@salesforce/label/c.gsResourcesItemPartnersLinkLabel';
import gsResourcesVideographyLabel from '@salesforce/label/c.gsResourcesVideographyLabel';
import gsResourcesVideographyLinkLabel from '@salesforce/label/c.gsResourcesVideographyLinkLabel';
import gseuResourcesItemQuestionsAnsweredLabel from '@salesforce/label/c.gseuResourcesItemQuestionsAnsweredLabel';
import gseuResourcesItemQuestionsAnsweredLinkLabel from '@salesforce/label/c.gseuResourcesItemQuestionsAnsweredLinkLabel';
import gseuResourcesItemAboutNPSPLabel from '@salesforce/label/c.gseuResourcesItemAboutNPSPLabel';
import gseuResourcesItemAboutNPSPLinkLabel from '@salesforce/label/c.gseuResourcesItemAboutNPSPLinkLabel';
import gseuResourcesItemWatchVideosLabel from '@salesforce/label/c.gseuResourcesItemWatchVideosLabel';
import gseuResourcesItemWatchVideosLinkLabel from '@salesforce/label/c.gseuResourcesItemWatchVideosLinkLabel';
import gseuResourcesItemWebinarsLabel from '@salesforce/label/c.gseuResourcesItemWebinarsLabel';
import gseuResourcesItemWebinarsLinkLabel from '@salesforce/label/c.gseuResourcesItemWebinarsLinkLabel';
import gseuResourcesItemCommunityGroupLabel from '@salesforce/label/c.gseuResourcesItemCommunityGroupLabel';
import gseuResourcesItemCommunityGroupLinkLabel from '@salesforce/label/c.gseuResourcesItemCommunityGroupLinkLabel';
import opensInNewLink from '@salesforce/label/c.opensInNewLink'



const ADMIN_RESOURCES = [
    {
        id: 1, 
        label: gsResourcesItemNonprofitCloudLabel, 
        linkLabel: gsResourcesItemNonprofitCloudLink,
        href: 'https://sforce.co/37GAkS1',
        ariaLabel: `${gsResourcesItemNonprofitCloudLink} ${opensInNewLink}`
    },
    {
        id: 2, 
        label: gsResourcesItemFundraisingLabel, 
        linkLabel: gsResourcesItemFundraisingLink,
        href: 'https://bit.ly/3grDDQP',
        ariaLabel: `${gsResourcesItemFundraisingLink} ${opensInNewLink}`
    },
    {
        id: 3,
        label: gsResourcesProgramManagementLabel,
        linkLabel: gsResourcesProgramManagementLink,
        href: 'https://bit.ly/3gnpB2y',
        ariaLabel: `${gsResourcesProgramManagementLink} ${opensInNewLink}`
    },
    {
        id: 4,
        label: gsResourcesMarketingEngagementLabel,
        linkLabel: gsResourcesMarketingEngagementLink,
        href: 'https://bit.ly/3gppF1Z',
        ariaLabel: `${gsResourcesMarketingEngagementLink} ${opensInNewLink}`
    },
    {
        id: 5,
        label: gsResourcesWebinarsLabel,
        linkLabel: gsResourcesWebinarsLink,
        href: 'https://sforce.co/3qCiyYI',
        ariaLabel: `${gsResourcesWebinarsLink} ${opensInNewLink}`
    },
    {
        id: 6,
        label: gsResourcesHubLabel,
        linkLabel: gsResourcesHubLink,
        href: 'https://sforce.co/2VQHVIg',
        ariaLabel: `${gsResourcesHubLink} ${opensInNewLink}`
    },
    {
        id: 7,
        label: gsResourcesPartnersLabel,
        linkLabel: gsResourcesPartnersLink,
        href: 'https://bit.ly/3gutvH5',
        ariaLabel: `${gsResourcesPartnersLink} ${opensInNewLink}`
    },
    {
        id: 8,
        label: gsResourcesVideographyLabel,
        linkLabel: gsResourcesVideographyLinkLabel,
        href: 'https://bit.ly/3qDURPA',
        ariaLabel: `${gsResourcesVideographyLinkLabel} ${opensInNewLink}`
    }
];

const END_USER_RESOURCES = [
    {
        id: 1,
        label: gseuResourcesItemQuestionsAnsweredLabel,
        linkLabel: gseuResourcesItemQuestionsAnsweredLinkLabel,
        href: 'https://sforce.co/3qGnlbu',
        ariaLabel: `${gseuResourcesItemQuestionsAnsweredLinkLabel} ${opensInNewLink}`
    },
    {
        id: 2,
        label: gseuResourcesItemAboutNPSPLabel,
        linkLabel: gseuResourcesItemAboutNPSPLinkLabel,
        href: 'https://sforce.co/3oCXOxY',
        ariaLabel: `${gseuResourcesItemAboutNPSPLinkLabel} ${opensInNewLink}`
    },
    {
        id: 3,
        label: gseuResourcesItemWatchVideosLabel,
        linkLabel: gseuResourcesItemWatchVideosLinkLabel,
        href: 'https://bit.ly/3n26U7d',
        ariaLabel: `${gseuResourcesItemWatchVideosLinkLabel} ${opensInNewLink}`
    },
    {
        id: 4,
        label: gseuResourcesItemWebinarsLabel,
        linkLabel: gseuResourcesItemWebinarsLinkLabel,
        href: 'https://sforce.co/33UBNmy',
        ariaLabel: `${gseuResourcesItemWebinarsLinkLabel} ${opensInNewLink}`
    },
    {
        id: 5,
        label: gseuResourcesItemCommunityGroupLabel,
        linkLabel: gseuResourcesItemCommunityGroupLinkLabel,
        href: 'https://bit.ly/2VQngnD',
        ariaLabel: `${gseuResourcesItemCommunityGroupLinkLabel} ${opensInNewLink}`
    }

]

export default class gsResources extends LightningElement {

    /**
    * @description To select which data display in this component
    */
    @api pageType = 'Admin';

    /**
    * Return the Resource list title to display in UI
    * @return      Title text
    * @see         Label
    */
    get title() {
        return gsResourcesTitle;
    }

    /**
    * Return the list of resources to display in UI
    * @return      List of resources
    * @see         List
    */
    get resources() {
        switch(this.pageType) {
            case 'Admin':
                return ADMIN_RESOURCES;
            case 'End User':
                return END_USER_RESOURCES;
            default:
                return []
        }
    }
}
