/*
    Copyright (c) 2017 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2017
*
* @group Resource Page
*
* @description Component, includes Getting started links.
*/

public with sharing class RP_GettingStartedController {

    private static final String CUSTOM_METADATA_LINKS_NAME = 'RP_UrlLinks';

    public LinksWrapper linksData { get; set;}

    public RP_GettingStartedController() {

        loadLinks();

    }

    private void loadLinks() {

        RP_Getting_Started_Links__mdt linksMetadata;

        linksMetadata = [SELECT
                            RP_Trailhead_Link__c,
                            RP_Salesforce_Org_Link__c,
                            RP_Us_Link__c,
                            RP_Npsp_Link__c,
                            RP_Webinar_Link__c,
                            RP_Customer_Journey_Link__c,
                            Label
                            FROM RP_Getting_Started_Links__mdt
                            WHERE DeveloperName = :CUSTOM_METADATA_LINKS_NAME
                            LIMIT 1
                        ];

        if (linksMetadata != null) {

            linksData = new LinksWrapper (linksMetadata);

        }

    }

    public class LinksWrapper {

        public String trailheadLink { get; set;}
        public String salesforceOrgLink { get; set;}
        public String usLink { get; set;}
        public String nspsLink { get; set;}
        public String webinarLink { get; set;}
        public String customerJourneyLink { get; set;}

        public LinksWrapper (RP_Getting_Started_Links__mdt linksData) {

            trailheadLink = !String.isBlank(linksData.RP_Trailhead_Link__c) ? linksData.RP_Trailhead_Link__c : null;

            salesforceOrgLink = !String.isBlank(linksData.RP_Salesforce_Org_Link__c) ? linksData.RP_Salesforce_Org_Link__c : null;

            usLink = !String.isBlank(linksData.RP_Us_Link__c) ? linksData.RP_Us_Link__c : null;

            nspsLink = !String.isBlank(linksData.RP_Npsp_Link__c) ? linksData.RP_Npsp_Link__c : null;

            webinarLink = !String.isBlank(linksData.RP_Webinar_Link__c) ? linksData.RP_Webinar_Link__c : null;

            customerJourneyLink = !String.isBlank(linksData.RP_Customer_Journey_Link__c) ? linksData.RP_Customer_Journey_Link__c : null;

        }

    }

}