import { LightningElement } from 'lwc';
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

export default class gsResources extends LightningElement {

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
        return [
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
        ];
    }
}