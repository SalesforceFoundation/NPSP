/*
    Copyright (c) 2011, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @date 2011 (2.3)
* @description The controller for the VF page invoked by using the campaign dedupe button from the campaign record 
*/
public without sharing class HH_CampaignDedupeBTN_CTRL {
    
    //HH campagin deduplication. Based on base classes by Evan Callahan and Kevin Bromer
    
    private Campaign campaign;
    private string CampaignMailingListReportId;
    private boolean haveReportID;  
    private npo02__Households_Settings__c hs;
    public string returnURL{get; private set;}
    final private string DUPETEXT = ' - Household Duplicate';
    
    //we get settings in the constructor, but if we don't have a report ID and query for it,
    //we want to update the old settings with the new report ID, but we can't do it in the consturctor
    //so we inform our action method to perform the update
    private boolean updateSettingsWithID = false; 
  
    public HH_CampaignDedupeBTN_CTRL(ApexPages.StandardController controller){   
        
        hs = HH_Households.getHouseholdsSettings();
        CampaignMailingListReportId = hs.npo02__Household_Mailing_List_ID__c; 
        haveReportID = true; 
      
        campaign = (Campaign)controller.getRecord();
        PageReference pageRef = new PageReference('/' + campaign.id);
        returnurl = pageref.getUrl();
        
        if ((CampaignMailingListReportId == null) || (CampaignMailingListReportId == '')){   
            //try looking it up by name...
            Report r = new Report();
            try{r = [select id from Report where DeveloperName = 'NPSP_Campaign_Household_Mailing_List'];}
            catch(QueryException e){
                haveReportID = false;
                showmsg(e.getMessage(), ApexPages.Severity.ERROR);
            }
            
            if(haveReportID){
                CampaignMailingListReportId = r.id;
                haveReportID = true;
                updateSettingsWithID = true;                                
            }                
        }
        
        campaign = [select id, name from campaign where id = :campaign.id];             
    }  
  
  
    //we'll run this from the pages action method
    public PageReference RunReport(){
    	Savepoint sp = Database.setSavepoint();
    	try {
	        string ActiveID = campaign.id;
	        ActiveID = ActiveID.substring(0,15);
	        string newPageUrl = '';
	        integer dupsmarked;
	        boolean redirectpage = false;
	        
	        //this dml need to be done by the action method        
	        if (updateSettingsWithID){
	            hs.npo02__Household_Mailing_List_ID__c = CampaignMailingListReportId;
	            update hs;
	        }
	        
	        if (!haveReportID){
	            string errormsg = 'Could not find report. Create a report with the Report Unique Name of \'NPSP_Campaign_Household_Mailing_List\'. NOTE: Report type should be Campaigns with Contacts. Filter for Member Status does not contain \'Duplicate\'';
	            showMsg(errormsg, ApexPages.Severity.ERROR);
	        }
	        
	        else{
	            dupsmarked = MarkDuplicates();
	            newPageURL = '/' + CampaignMailingListReportId + '?retURL=/' + ActiveID + '&scopeid_lkid=' + ActiveID + '&scope=one&scopeid=' + Campaign.Name;
	            redirectpage = true;                
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
    		ERR_Handler.processError(e, ERR_Handler.Context.HH);
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    		return null;
    	}
    }

    private integer MarkDuplicates(){
    // mark duplicate households in campaign membership

        
        
        //check for the Household Duplicate status values we need
        Map<string, boolean> StatusLabels = new Map<string, boolean>();
        CampaignMemberStatus[] statuses = [select label, hasResponded from CampaignMemberStatus where CampaignId=:campaign.id];
        
        list<CampaignMember> dupeMembers = new list<CampaignMember>();
        
        for (CampaignMemberStatus cms : statuses) StatusLabels.put(cms.label, cms.hasResponded);
        
        integer nextSortOrder = [select sortorder from CampaignMemberStatus where CampaignId=:campaign.Id order by sortorder desc limit 1].SortOrder + 1;
        
        CampaignMemberStatus[] newStatuses = new CampaignMemberStatus[]{};
          
        set<id> HouseholdIDSet = new set<id>();        
    
        for (CampaignMember m : [Select Id, ContactId, Contact.Name, Contact.npo02__household__c, Contact.AccountId, Contact.Account.npe01__SYSTEM_AccountType__c, Status 
            From CampaignMember where CampaignId=:campaign.Id and ContactId != null and 
                (Contact.npo02__household__c != null or Contact.Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE)
                order by Contact.npo02__TotalOppAmount__c desc]) {
            
            //do not want null status
            if (m.Status==null) m.Status = statuses[0].label;
      
            string newStatus = null;
            
            ID hhId = (m.Contact.Account.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE) ?
                m.Contact.AccountId : m.Contact.npo02__household__c;
      /*
            //if this contact's household is already in the set, its a dupe from this household
            //also filter any we've already marked 
            if (HouseholdIDSet.contains(m.Contact.npo02__household__c) && !m.Status.endsWith(DupeText)) {
                    string newStatus =  m.Status + DupeText;                
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
            if(HouseholdIDSet.contains(hhId)){
                if (!m.Status.endsWith(DupeText)) {
                    newStatus =  m.Status + DupeText;
                }
            }
             
            else{
                HouseholdIDSet.add(hhId);
                
                if (m.Status.endsWith(DupeText)) {
                    newStatus =  m.Status.substring(0, m.status.length()-DupeText.length());                
                }
            }
            
            if (newStatus != null) {     
                
                dupeMembers.add(new CampaignMember(Id = m.Id, Status = newStatus)); 
                
                if (!StatusLabels.containsKey(newStatus)) {
                    newStatuses.add(new CampaignMemberStatus(label=newStatus, campaignid=campaign.Id, hasResponded=StatusLabels.get(m.Status), sortorder=nextSortOrder));
                    StatusLabels.put(newStatus, StatusLabels.get(m.Status));
                    nextSortOrder++;
                }
            }
        }
        
        integer returnsize = 0;
        try{
            if (!newStatuses.isEmpty()) insert newStatuses;
            if (!dupeMembers.isEmpty()){
                 update dupeMembers;
                 returnsize = dupeMembers.size();                
            }
        }            
        catch (Exception e){
        	ERR_Handler.processError(e, ERR_Handler.Context.HH);
            showMsg(e.getMessage(), ApexPages.Severity.ERROR);  
        }
        
        return returnsize;
    }
    
    private void showMsg(String arg, ApexPages.Severity severity){
        ApexPages.Message myMsg = new ApexPages.Message(severity,arg);
        ApexPages.addMessage(myMsg);
    } 


}