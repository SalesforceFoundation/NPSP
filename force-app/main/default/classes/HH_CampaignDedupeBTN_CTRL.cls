/*
    Copyright (c) 2011,2014 Salesforce.org
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
* @date 2011 (2.3)
* @group Households
* @description The controller for the VF page invoked by using the campaign dedupe button from the campaign record
*/
public without sharing class HH_CampaignDedupeBTN_CTRL {

    //HH campagin deduplication. Based on base classes by Evan Callahan and Kevin Bromer

    private Campaign campaign;
    private string campaignMailingListReportId;
    private boolean haveReportID;
    private npo02__Households_Settings__c hs;

    /*******************************************************************************************************
    * @description the URL of the Campaign's detail page
    */
    public string returnURL { get; private set; }

    /*******************************************************************************************************
    * @description URL to the Campaign Deduplication Report
    */
    public string reportURL { get; private set; }

    //we get settings in the constructor, but if we don't have a report ID and query for it,
    //we want to update the old settings with the new report ID, but we can't do it in the consturctor
    //so we inform our action method to perform the update
    private boolean updateSettingsWithID = false;

    @TestVisible
    public Boolean hasAccess {
        get {
            if (hasAccess == null) {
                hasAccess = getCurrentUserHasAccess();
            }
            return hasAccess;
        }
        private set;
    }

    @TestVisible
    private UTIL_Permissions perms {
        get {
            if (perms == null) {
                perms = new UTIL_Permissions();
            }

            return perms;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Constructor
    * @param controller StandardController to a Campaign
    ********************************************************************************************************/
    public HH_CampaignDedupeBTN_CTRL(ApexPages.StandardController controller){

        hs = UTIL_CustomSettingsFacade.getHouseholdsSettings();
        campaignMailingListReportId = hs.npo02__Household_Mailing_List_ID__c;
        haveReportID = true;

        campaign = (Campaign)controller.getRecord();
        PageReference pageRef = new PageReference('/' + campaign.id);
        returnURL = pageref.getUrl();

        if ((campaignMailingListReportId == null) || (campaignMailingListReportId == '')){
            //try looking it up by name...
            Report r = new Report();
            try{
                r = [select id from Report where DeveloperName = 'NPSP_Campaign_Household_Mailing_List_V2'];
            } catch(QueryException e){
                haveReportID = false;
                showmsg(e.getMessage(), ApexPages.Severity.ERROR);
            }

            if(haveReportID){
                campaignMailingListReportId = r.id;
                haveReportID = true;
                updateSettingsWithID = true;
            }
        }

        campaign = [select id, name, NumberOfContacts from campaign where id = :campaign.id];
    }

    /*******************************************************************************************************
    * @description Action Method that is run by the page's action method to run the deduplication procedure
    * @return PageReference url to the Report if successful, this page if an error.
    ********************************************************************************************************/
    public PageReference RunReport(){
        Savepoint sp = Database.setSavepoint();
        try {
            if (!hasAccess) {
                throw new UTIL_Permissions.InsufficientPermissionException(System.Label.commonAccessErrorMessage);
            }

            string ActiveID = campaign.id;
            ActiveID = ActiveID.substring(0,15);
            string newPageUrl = '';
            integer dupsmarked;
            boolean redirectpage = false;

            //this dml need to be done by the action method
            if (updateSettingsWithID){
                hs.npo02__Household_Mailing_List_ID__c = campaignMailingListReportId;
                UTIL_DMLService.updateRecord(hs);
            }

            if (!haveReportID){
                showMsg(System.Label.hhCmpDedupeNoReport, ApexPages.Severity.ERROR);
            }

            else{
                dupsmarked = MarkDuplicates();

                if (USER_UserService.isUserRunningLightning()) {
                    newPageUrl = USER_UserService.getLightningBaseURL(campaignMailingListReportId) + '?fv0=' + ActiveID;
                } else {
                    newPageUrl = '/' + campaignMailingListReportId + '?retURL=/' + ActiveID + '&pv0=' + ActiveID;
                }

                if (dupsmarked == -1) {
                    showMsg(System.Label.hhCmpDedupeBatchMessage, ApexPages.Severity.INFO);
                    reportURL = newPageURL;
                } else {
                    redirectpage = true;
                }
            }

            if (redirectPage){
                PageReference pageref = new PageReference(newPageURL);
                pageRef.setRedirect(true);
                return pageRef;
            }
            else{
                return null;
            }
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.HH);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    /*******************************************************************************************************
    * @description marks duplicate households in campaign membership
    * @return integer the number of duplicates found.  if -1, the process is being done in batch.
    ********************************************************************************************************/
    private integer MarkDuplicates(){
        string strSoql = strSoqlDedupe();

        if (campaign.NumberOfContacts > 10000) {
            MarkDuplicatesBatch(strSoql);
            return -1;
        } else {
            list<CampaignMember> listCM = database.query(strSoql);
            return MarkDuplicatesFromList(campaign.Id, listCM);
        }
    }

    /*******************************************************************************************************
    * @description kick off the batch job of marking duplicates
    * @return void
    ********************************************************************************************************/
    private void MarkDuplicatesBatch(string strSoql) {
        HH_CampaignDedupe_BATCH batch = new HH_CampaignDedupe_BATCH(campaign.Id, strSoql);
        database.executeBatch(batch, 2000);
    }

    /*******************************************************************************************************
    * @description return the soql needed for getting all CampaignMembers
    * @return string
    ********************************************************************************************************/
    private string strSoqlDedupe() {
        string strSoql;
        strSoql = 'Select Id, ContactId, Contact.Name, Contact.npo02__household__c, Contact.AccountId, Contact.HHId__c, Contact.Account.npe01__SYSTEM_AccountType__c, Status ';
        strSoql += 'From CampaignMember where CampaignId = \'' + campaign.Id + '\' and ContactId != null and ';
        strSoql += '(Contact.npo02__household__c != null or Contact.Account.npe01__SYSTEM_AccountType__c = \'' + CAO_Constants.HH_ACCOUNT_TYPE + '\') ';
        strSoql += 'order by Contact.HHId__c, Contact.npo02__TotalOppAmount__c desc';
        return strSoql;
    }

    /*******************************************************************************************************
    * @description the real worker that takes the list of CampaignMembers, and marks any in the list that are duplicates in the household.
    * @param Id the campaign's Id
    * @param listCM list of CampaignMember records to evaluate
    * @return integer the number of duplicates identified
    ********************************************************************************************************/
    public static integer MarkDuplicatesFromList(ID campaignId, list<CampaignMember> listCM) {

        final String DUPE_STATUS_SUFFIX = System.Label.hhCmpDedupeStatus;

        //check for the Household Duplicate status values we need
        Map<string, boolean> StatusLabels = new Map<string, boolean>();
        CampaignMemberStatus[] statuses = [select label, hasResponded from CampaignMemberStatus where CampaignId=:campaignId];

        list<CampaignMember> dupeMembers = new list<CampaignMember>();

        for (CampaignMemberStatus cms : statuses) StatusLabels.put(cms.label, cms.hasResponded);

        List<CampaignMemberStatus> campMemberStatuses = [select sortorder from CampaignMemberStatus where CampaignId=:campaignId order by sortorder desc limit 1];
        //Giving it a default value because we cannot access CampaignMemberStatus object in tests without the seeAllData=true annotation
        //http://salesforce.stackexchange.com/questions/14051/campaignmemberstatus-records-only-testable-with-seealldata-flag
        Integer nextSortOrder = 0;
        if(campMemberStatuses.size() > 0)
            nextSortOrder = campMemberStatuses[0].SortOrder + 1;
        CampaignMemberStatus[] newStatuses = new CampaignMemberStatus[]{};

        set<id> HouseholdIDSet = new set<id>();

        for (CampaignMember m : listCM) {

            //do not want null status
            if (m.Status==null) m.Status = statuses[0].label;

            string newStatus = null;

            ID hhId = m.Contact.HHId__c;
      /*
            //if this contact's household is already in the set, its a dupe from this household
            //also filter any we've already marked
            if (HouseholdIDSet.contains(m.Contact.npo02__household__c) && !m.Status.endsWith(DUPE_STATUS_SUFFIX)) {
                    string newStatus =  m.Status + DUPE_STATUS_SUFFIX;
                    dupeMembers.add(new CampaignMember(Id = m.Id, Status = newStatus));
                    if (!StatusLabels.containsKey(newStatus)) {
                        newStatuses.add(new CampaignMemberStatus(label=newStatus, campaignid=campaign.Id, hasResponded=StatusLabels.get(m.Status), sortorder=nextSortOrder));
                        StatusLabels.put(newStatus, StatusLabels.get(m.Status));
                        nextSortOrder++;
                    }
            }
            else{
                HouseholdIDSet.add(m.Contact.npo02__household__c);
            }
        */
            /*PATCH SUBMITTED PER ISSUE 256 */

            //mark it as a duplicate if not already marked
            //if the HH id is not in the set, it's not a duplicate.  If it's marked as such,
            //(e.g. from a previous time the report was run), unmark it.
            if (HouseholdIDSet.contains(hhId)){
                if (!m.Status.endsWith(DUPE_STATUS_SUFFIX)) {
                    // handle long status's that would go over limit of 40 characters
                    Integer cch = m.Status.length();
                    if (cch + DUPE_STATUS_SUFFIX.length() > 40) {
                        cch = 40 - DUPE_STATUS_SUFFIX.length();
                    }
                    newStatus =  m.Status.left(cch) + DUPE_STATUS_SUFFIX;
                }
            }

            else{
                HouseholdIDSet.add(hhId);

                if (m.Status.endsWith(DUPE_STATUS_SUFFIX)) {
                    newStatus =  m.Status.substring(0, m.status.length()-DUPE_STATUS_SUFFIX.length());
                }
            }

            if (newStatus != null) {
                dupeMembers.add(new CampaignMember(Id = m.Id, Status = newStatus));

                if (StatusLabels.size() > 0 && !StatusLabels.containsKey(newStatus)) {
                    Boolean hasResponded = StatusLabels.get(m.Status) == true;

                    newStatuses.add(new CampaignMemberStatus(label=newStatus, campaignid=campaignId, hasResponded=hasResponded, sortorder=nextSortOrder));
                    StatusLabels.put(newStatus, hasResponded);
                    nextSortOrder++;
                }
            }
        }

        integer returnsize = 0;
        Savepoint sp = Database.setSavepoint();
        try{
            if (!newStatuses.isEmpty()) UTIL_DMLService.insertRecords(newStatuses);
            if (!dupeMembers.isEmpty()){
                 UTIL_DMLService.updateRecords(dupeMembers);
                 returnsize = dupeMembers.size();
            }
        }
        catch (Exception e){
        	Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.HH);
        }

        return returnsize;
    }

    private Boolean getCurrentUserHasAccess() {
        Boolean accessOK = false;

        if (UTIL_Permissions.canUpdate('CampaignMember', 'Status', false)) {
            Set<SObjectField> cmsFields = new Set<SObjectField>{
                CampaignMemberStatus.fields.CampaignId,
                CampaignMemberStatus.fields.Label,
                CampaignMemberStatus.fields.HasResponded,
                CampaignMemberStatus.fields.SortOrder
            };
            if ((perms.canRead(CampaignMemberStatus.getSObjectType(), cmsFields) &&
                    perms.canCreate(CampaignMemberStatus.getSObjectType(), cmsFields))) {
                accessOK = true;
            }
        }

        return accessOK;
    }

    /*******************************************************************************************************
    * @description Adds a Message to the visualforce page
    * @param arg the message string
    * @param severity
    * @return void
    ********************************************************************************************************/
    private static void showMsg(String arg, ApexPages.Severity severity){
        ApexPages.Message myMsg = new ApexPages.Message(severity,arg);
        ApexPages.addMessage(myMsg);
    }


}