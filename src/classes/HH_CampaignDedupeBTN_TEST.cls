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
* @description test class for the campaign dedupe button from the campaign record 
*/
@isTest
private class HH_CampaignDedupeBTN_TEST {  
  
  public static testMethod void testCampaignHHReport(){
      Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,                    
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null,                     
                    Use_Fiscal_Year_for_Rollups__c = true, 
                    Rollup_N_Day_Value__c = 10,
                    Household_Mailing_List_ID__c = null                    
                ));
                
    // create test data
    Account acct = new Account (
      Name='Test Account'
    );
    insert acct;
    
    Contact con = new Contact (
      FirstName='Kevin',
      LastName='Test',
      AccountId = acct.id,    
      TotalOppAmount__c = 100
    );
    insert con;
    id hhid = [select Household__r.id from Contact where id = :con.id].Household__r.id;
    system.debug('HHID IS===================' + hhid);
    Contact con2 = new Contact (
      FirstName = 'Amy',
      LastName = 'Test',
      AccountId = acct.id,            
      household__c = hhid
    );
    system.debug('HHID IS NOW===================' + hhid);
    
    system.assert(con2.Household__c != null);
    insert con2;
    
    Campaign camp = new Campaign (
      Name = 'MyCampaign',
      Status = 'Planned',
      isActive = true
    );
    insert camp;
    
    CampaignMember campm1 = new CampaignMember(
      CampaignID = camp.id,
      ContactID = con.id      
    );
    insert campm1;
    
    CampaignMember campm2 = new CampaignMember(
      CampaignID = camp.id,
      ContactID = con2.id      
    );
    insert campm2;
        
    //now run our report
    ApexPages.StandardController sc = new ApexPages.StandardController(camp);
    HH_CampaignDedupeBTN_CTRL deduper = new HH_CampaignDedupeBTN_CTRL(sc);
    PageReference pr = deduper.runReport();
    
    system.assertEquals([select Status from CampaignMember where id = :campm1.id].Status + ' - Household Duplicate', [select Status from CampaignMember where id = :campm2.Id].Status);    
  
  }
}