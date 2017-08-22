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
* @group Settings
* @description Unit tests for STG_PanelHouseholds_CTRL class
*/
@isTest
private class STG_PanelHouseholds_TEST {
    /*********************************************************************************************************
    * @description Constant representing Household_Naming_Settings__c.Household_Name_Format__c field name
    */
    private static final String HH_NAME_FORMAT_FIELD = 'Household_Name_Format__c';

    /*********************************************************************************************************
    * @description Constant representing Household_Naming_Settings__c.Formal_Greeting_Format__c field name
    */
    private static final String HH_FORMAL_GREETING_FORMAT_FIELD = 'Formal_Greeting_Format__c';
    
    /*********************************************************************************************************
    @description 
        Tests panel returns expected panel Id
    verify:
        The method returns panel Id.  
    **********************************************************************************************************/   
    private static testMethod void testPanelHasPanelId() {
        STG_PanelHouseholds_CTRL panel = new STG_PanelHouseholds_CTRL();
        System.assertEquals('idPanelHH', panel.idPanel());
    }

    /*********************************************************************************************************
    * @description 
        Tests save of Automatic Household Naming 
    verify:
        The settings field is saved as user specified it  
    **********************************************************************************************************/   
    private static testMethod void testSaveSettingsSavesAutomaticHHNaming() {
        STG_Panel.stgService.stgHH.npo02__Advanced_Household_Naming__c = false; 

        STG_PanelHouseholds_CTRL panel = new STG_PanelHouseholds_CTRL();
        panel.saveSettings();

        System.assertEquals(false, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Advanced_Household_Naming__c, 'Automatic Household Naming should be unchecked');
    }

    /*********************************************************************************************************
    @description 
        Tests isValidSettings() when the Account Model is set to 'Household Account' but 
        Household Rules are not set to 'No Contacts'
    verify:
        The method returns false.    
        The page contains an error message.    
    **********************************************************************************************************/ 
    private static testMethod void testPanelPageHasErrorWhenAccountModelIsNotAsExpected() {
        UTIL_UnitTestData_TEST.setupHHNamingSettings();

        STG_Panel.stgService.stgHH.npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR;
        STG_Panel.stgService.stgCon.npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR;
        
        Test.setCurrentPage(Page.STG_PanelHouseholds);

        STG_PanelHouseholds_CTRL ctrl = new STG_PanelHouseholds_CTRL();
        System.assertEquals(false, ctrl.isValidSettings(), 'Household Naming Settings should be invalid');     
        
        UTIL_UnitTestData_TEST.assertPageHasError(Label.stgValidationHHAccountHHRules); 
    }

    /*********************************************************************************************************
    @description 
        Tests that the name specs are valid in the Households panel regardless 
        if the Automatic Household Naming is checked
    verify:
        isValidSettings() returns false when any Household Naming Settings field is invalid.
        isValidSettings() returns true when all Household Naming Settings fields are valid.
    **********************************************************************************************************/ 
    private static testMethod void testPanelValidatesHHNamingSettingsWhetherAutomaticHHNamingIsOn() {
        STG_PanelHouseholds_CTRL panel = new STG_PanelHouseholds_CTRL();        

        for (Boolean isAutomaticHouseholdNaming : new Boolean[] { true, false }) {
            STG_Panel.stgService.stgHH.npo02__Advanced_Household_Naming__c = isAutomaticHouseholdNaming;

            System.assertEquals(true, panel.isValidSettings(), 'Household Naming Settings should be valid');        

            STG_Panel.stgService.stgHN.Household_Name_Format__c = '{!{!bogus}}';
            System.assertEquals(false, panel.isValidSettings(), 'Household Name Format should be invalid');      

            STG_Panel.stgService.stgHN.Household_Name_Format__c = '{!{!FirstName}} {!LastName} Family';        
            STG_Panel.stgService.stgHN.Formal_Greeting_Format__c = '{!{!bogus}}';
            System.assertEquals(false, panel.isValidSettings(), 'Household Formal Greeting Format should be invalid');     

            STG_Panel.stgService.stgHN.Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName}} {!LastName}';               
            STG_Panel.stgService.stgHN.Informal_Greeting_Format__c = '{!{!bogus}}';
            System.assertEquals(false, panel.isValidSettings(), 'Household Informal Greeting Format should be invalid');     

            STG_Panel.stgService.stgHN.Informal_Greeting_Format__c = '{!{!FirstName}}';
            System.assertEquals(true, panel.isValidSettings(), 'Household Naming Settings should be valid');   
        }     
    }

    /*********************************************************************************************************
    @description 
        Tests isValidSettings() when Household Naming Settings fields are invalid
    verify:
        The method returns false.    
        The page contains error messages for all invalid fields.    
    **********************************************************************************************************/ 
    private static testMethod void testPanelPageHasErrorWhenHHNamingSettingsFieldIsInvalid() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings();
        settings.Household_Name_Format__c = '{!{!FirstName}} {!LastName}} Household';//invalid format
        settings.Formal_Greeting_Format__c = '{!Salutation}}}} {!LastName}';//invalid format
        
        Test.setCurrentPage(Page.STG_PanelHouseholds);

        STG_PanelHouseholds_CTRL ctrl = new STG_PanelHouseholds_CTRL();
        System.assertEquals(false, ctrl.isValidSettings(), 'Household Naming Settings should be invalid'); 

        for (String fieldName : new Set<String>{ HH_NAME_FORMAT_FIELD, HH_FORMAL_GREETING_FORMAT_FIELD }) {          
            String fieldLabel = UTIL_Describe.getFieldLabel(
                UTIL_Namespace.StrTokenNSPrefix('Household_Naming_Settings__c'), 
                UTIL_Namespace.StrTokenNSPrefix(fieldName)
            );
            
            UTIL_UnitTestData_TEST.assertPageHasError(fieldLabel); 
            UTIL_UnitTestData_TEST.assertPageHasError('Invalid field'); 
        }
    }

    /*********************************************************************************************************
    @description 
        Tests that isValidSettings() validates user changed Household Naming Settings 
    verify:
        The method returns false if a Household Naming Settings field is invalid 
    **********************************************************************************************************/ 
    private static testMethod void testPanelValidatesUserChangesOfHHNamingSettings() {        
        UTIL_UnitTestData_TEST.setupHHNamingSettings();
        
        Test.setCurrentPage(Page.STG_PanelHouseholds);

        STG_PanelHouseholds_CTRL ctrl = new STG_PanelHouseholds_CTRL();
        System.assertEquals(true, ctrl.isValidSettings(), 'Household Naming Settings should be valid');      
        
        STG_Panel.stgService.stgHN.Household_Name_Format__c = '{!{!FirstName}} {!LastName}} Household'; //invalid format        
        System.assertEquals(false, ctrl.isValidSettings(), 'Household Naming Settings should be invalid');    
        UTIL_UnitTestData_TEST.assertPageHasError('Invalid field'); 

        STG_Panel.stgService.stgHN.Household_Name_Format__c = '{!{!FirstName} {!LastName}} Household'; 
        System.assertEquals(true, ctrl.isValidSettings(), 'Household Naming Settings should be valid');      
    }

    /*********************************************************************************************************
    @description 
        Tests strNameSpecExample when a Household Naming Settings format field is invalid
    verify:
        The method throws an exception
    **********************************************************************************************************/ 
    private static testMethod void testExampleNameThrowsExceptionWhenHHNameFormatFieldIsInvalid() {        
        UTIL_UnitTestData_TEST.setupInvalidHHNamingSettings();

        try {
            String exampleName = STG_PanelHouseholds_CTRL.strNameSpecExample(STG_Panel.stgService.stgHN, HH_NAME_FORMAT_FIELD, 2);

            System.assert(false, 'Expected exception for invalid format field');
        } catch(Exception e) {
            System.assert(e.getMessage().contains('Invalid field'), 'An exception should contain Invalid Field message instead: ' + e.getMessage());
        }    
    }

    /*********************************************************************************************************
    @description 
        Tests strNameSpecExample when a Household Name Format field is valid
    verify:
        The method returns a Household Name example 
    **********************************************************************************************************/ 
    private static testMethod void testExampleNameIsExpectedWhenHHNameFormatFieldIsValid() {        
        UTIL_UnitTestData_TEST.setupHHNamingSettings();

        String exampleName = STG_PanelHouseholds_CTRL.strNameSpecExample(STG_Panel.stgService.stgHN, HH_NAME_FORMAT_FIELD, 2);

        System.assert(String.isNotBlank(exampleName), 'An example name should be returned');
    }

    /*********************************************************************************************************
    @description 
        Tests strNameSpecExample when Implementing Class is invalid
    verify:
        The method returns an error message
    **********************************************************************************************************/ 
    private static testMethod void testExampleNameIsAnErrorWhenImplementingClassIsInvalid() {        
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings();
        settings.Implementing_Class__c = 'foo';

        String exampleName = STG_PanelHouseholds_CTRL.strNameSpecExample(STG_Panel.stgService.stgHN, HH_NAME_FORMAT_FIELD, 2);

        System.assertEquals(Label.stgErrorInvalidClass, exampleName, 'Expected error message should be returned');
    }
    
}