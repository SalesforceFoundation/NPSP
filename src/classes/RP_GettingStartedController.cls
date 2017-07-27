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

    public LinksWrapper linksData {get; set;}

    public RP_GettingStartedController() {

        linksData = new LinksWrapper ();
    }

    public class LinksWrapper {

        public String trailheadLink {get; set;}
        public String salesforceOrgLink {get; set;}
        public String usLink {get; set;}
        public String nspsLink {get; set;}
        public String webinarLink {get; set;}
        public String customerJourneyLink {get; set;}

        public LinksWrapper () {

            trailheadLink = !String.isBlank(RP_Constants.RP_TRAILHEAD_LINK) ? RP_Constants.RP_TRAILHEAD_LINK : null;

            salesforceOrgLink = !String.isBlank(RP_Constants.RP_SALESFORCE_ORG_LINK) ? RP_Constants.RP_SALESFORCE_ORG_LINK : null;

            usLink = !String.isBlank(RP_Constants.RP_US_LINK) ? RP_Constants.RP_US_LINK : null;

            nspsLink = !String.isBlank(RP_Constants.RP_NPSP_LINK) ? RP_Constants.RP_NPSP_LINK : null;

            webinarLink = !String.isBlank(RP_Constants.RP_WEBINAR_LINK) ? RP_Constants.RP_WEBINAR_LINK : null;

            customerJourneyLink = !String.isBlank(RP_Constants.RP_CUSTOMER_JOURNEY_LINK) ? RP_Constants.RP_CUSTOMER_JOURNEY_LINK : null;
        }
    }
}