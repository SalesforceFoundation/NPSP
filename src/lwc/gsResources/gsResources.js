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



const ADMIN_RESOURCES = [
    {
        id: 1, 
        label: gsResourcesItemNonprofitCloudLabel, 
        linkLabel: gsResourcesItemNonprofitCloudLink,
        href: 'https://trailhead.salesforce.com/en/content/learn/modules/nonprofit-cloud-basics'
    },
    {
        id: 2, 
        label: gsResourcesItemFundraisingLabel, 
        linkLabel: gsResourcesItemFundraisingLink,
        href: 'https://pub.s7.exacttarget.com/twkj3twkqri'
    },
    {
        id: 3,
        label: gsResourcesProgramManagementLabel,
        linkLabel: gsResourcesProgramManagementLink,
        href: 'https://pub.s7.exacttarget.com/twkj3twkqri'
    },
    {
        id: 4,
        label: gsResourcesMarketingEngagementLabel,
        linkLabel: gsResourcesMarketingEngagementLink,
        href: 'https://pub.s7.exacttarget.com/twkj3twkqri'
    },
    {
        id: 5,
        label: gsResourcesWebinarsLabel,
        linkLabel: gsResourcesWebinarsLink,
        href: 'https://cloud.mail.salesforce.com/event-calendar/#&product=.NonprofitCloud'
    },
    {
        id: 6,
        label: gsResourcesHubLabel,
        linkLabel: gsResourcesHubLink,
        href: 'https://powerofus.force.com/s/group/0F980000000CjVbCAK/getting-started-with-salesforce'
    },
    {
        id: 7,
        label: gsResourcesPartnersLabel,
        linkLabel: gsResourcesPartnersLink,
        href: 'https://www.salesforce.org/nonprofit/find-partner/'
    },
    {
        id: 8,
        label: gsResourcesVideographyLabel,
        linkLabel: gsResourcesVideographyLinkLabel,
        href: 'https://www.youtube.com/channel/UC8kDDLRZzDdOBS24al99Kag'
    }
];

const END_USER_RESOURCES = [
    {
        id: 1,
        label: gseuResourcesItemQuestionsAnsweredLabel,
        linkLabel: gseuResourcesItemQuestionsAnsweredLinkLabel,
        href: 'https://powerofus.force.com/publogin'
    },
    {
        id: 2,
        label: gseuResourcesItemAboutNPSPLabel,
        linkLabel: gseuResourcesItemAboutNPSPLinkLabel,
        href: 'https://powerofus.force.com/s/article/NPSP-Documentation'
    },
    {
        id: 3,
        label: gseuResourcesItemWatchVideosLabel,
        linkLabel: gseuResourcesItemWatchVideosLinkLabel,
        href: 'https://www.youtube.com/channel/UC8kDDLRZzDdOBS24al99Kag'
    },
    {
        id: 4,
        label: gseuResourcesItemWebinarsLabel,
        linkLabel: gseuResourcesItemWebinarsLinkLabel,
        href: 'https://cs.salesforce.com/events?filter=true&product=nonprofit-cloud%2Csalesforce.org&category=®ion=&language=&type=&search=&startDate=&endDate=&dateSpan=custom'
    },
    {
        id: 5,
        label: gseuResourcesItemCommunityGroupLabel,
        linkLabel: gseuResourcesItemCommunityGroupLinkLabel,
        href: 'https://trailblazercommunitygroups.com/'
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