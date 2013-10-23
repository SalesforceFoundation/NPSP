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
* @date 2011 (2.0)
* @description test the Household Settings VF page 
*/
@isTest
private class STTG_HouseholdsSettings_TEST {

     public static testMethod void TEST_householdsSettings() {
        
        Test.setCurrentPageReference(new PageReference('Page.householdsSettings'));
        
        Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(new Households_Settings__c (Household_Rules__c = Households.ALL_INDIVIDUALS_PROCESSOR));
        
        //pass the controller into the extension
        STTG_HouseholdsSettings_CTRL controller = new STTG_HouseholdsSettings_CTRL(); 
        controller.getSettingsFirstTime();
        system.assertNotEquals(null,controller.pageSettings);
        
        List<SelectOption> householdrules =  controller.gethouseholdrules(); 
        system.assertEquals(3,householdrules.size());
        
        List<SelectOption> oppStages = controller.getoppStages();
        system.assertNotEquals(null,oppStages);
        
        List<SelectOption> conRoles = controller.getcontactRoles();
        system.assertNotEquals(null,conRoles);
        
        List<SelectOption> opptypes = controller.getTypes();
        system.assertNotEquals(null,opptypes);
        
        List<SelectOption> oppRTypes = controller.getRTypes();
        system.assertNotEquals(null,oppRTypes);
        controller.acctRTs.add(RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'));
        controller.contactRTs.add(RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'));
        
        controller.acctTypes.add('In-Kind');
        controller.contactTypes.add('In-Kind');
        controller.pageSettings.Enable_Opp_Rollup_Triggers__c = true;
        controller.editHouseholdSettings();
        controller.editRollupSettings();
        controller.updateSettings();  
        controller.cancel();
        controller.deleteErrors();
        controller.activateHouseholdNaming();
        system.assertEquals(true, controller.runningBatch);        
        
        //test package update calls
        String myver = controller.getMyVersion();
        system.assertEquals(String.valueOf(Package.Version.Request), myver);
        String maxver = controller.getMaxVersion();
        String uUrl = controller.getUpdateURL();
        String lastUpdate = controller.getLastUpdate();
        String pkupdates = controller.getpkgupdatestatus();              
    }    

}