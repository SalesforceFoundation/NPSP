/*
    Copyright (c) 2015, Salesforce.org
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
* @author Salesforce.com Foundation
* @date 2015
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunities.htm
* @description Handles adding and updating campaign members based on campaign donations.
*/
public with sharing class OPP_CampaignMember_TDTM extends TDTM_Runnable {
    
    /**@description Lists to pass to CON_AddToCampaign*/
    private list<Id> listContactId = new list<Id>();
    private list<Id> listCampaignId = new list<Id>();
    private list<String> listMemberStatus = new list<String>();

    /**@description Static flag to prevent recursion. */
    public static boolean hasRun = false;

    /*******************************************************************************************************
    * @description Creates and updates campaign members based on opportunity primary contact, primary 
    * campaign source, and the primary contact status field.
    * @param listNew the list of Opportunities from trigger new. 
    * @param listOld the list of Opportunities from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult the describe for Opportunities.
    * @return dmlWrapper Campaign Members to insert or update.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        
        dmlWrapper dmlWrapper = new DmlWrapper();

        if (hasRun)
            return dmlWrapper;
            
        for (integer i=0; i<newlist.size(); i++) {

            Opportunity opp = (Opportunity)newlist[i];
            
            //if status is "omit", do nothing for this opportunity
            if ((!string.isBlank(opp.Primary_Contact_Campaign_Member_Status__c) && 
                    opp.Primary_Contact_Campaign_Member_Status__c.equalsIgnoreCase(Label.CampaignMemberStatusOmit))) {
                continue;
            }

            if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                addOppMemberFields(opp);
            }
            
            if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                Opportunity oldOpp = (Opportunity)oldlist[i];

                //the status is blank and we're changing closed/won status
                if (string.isBlank(opp.Primary_Contact_Campaign_Member_Status__c) && 
                    (opp.IsClosed != oldOpp.isClosed || opp.IsWon != oldOpp.isWon)) {
                    
                    addOppMemberFields(opp);
                //the primary contact, campaign, or status changed
                } else if (opp.Primary_Contact__c != oldOpp.Primary_Contact__c || 
                    opp.CampaignId != oldOpp.CampaignId || 
                    opp.Primary_Contact_Campaign_Member_Status__c != oldOpp.Primary_Contact_Campaign_Member_Status__c) {
                    
                    addOppMemberFields(opp);
                }
            }
        }
        
        if (!listContactId.isEmpty())
            dmlWrapper = CON_AddToCampaign.CreateCampaignMembers(listContactId, listCampaignId, listMemberStatus);

        hasRun = true;
        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Adds a Contact Id, Campaign Id, and Status to our three lists. If the opportunity has a
    * status it is used, otherwise a default is used based on if the opportunity is closed/won or not.
    * @param Opp The current opportunity.
    * @return void This method adds to three lists and returns nothing.
    ********************************************************************************************************/
    private void addOppMemberFields(Opportunity opp) {
        if (opp.Primary_Contact__c == null || opp.CampaignId == null)
            return;

        //if no status is provided, default to a responded status if the opp is closed/won
        //otherwise default to a non-responded status
        if (string.isBlank(opp.Primary_Contact_Campaign_Member_Status__c)) {
            if (opp.isClosed && opp.isWon) {
                listMemberStatus.add(Label.campaignMemberStatusResponded);
            } else {
                listMemberStatus.add(Label.campaignMemberStatusNonResponded);
            }
        } else listMemberStatus.add(opp.Primary_Contact_Campaign_Member_Status__c);

        listCampaignId.add(opp.CampaignId);
        listContactId.add(opp.Primary_Contact__c);
    }
}