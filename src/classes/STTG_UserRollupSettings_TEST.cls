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
* @description test class for the User Rollup Settings wizard  
*/
@isTest
private class STTG_UserRollupSettings_TEST {

    /*** Test Methods ***/
        
    public static testMethod void TEST_userRollupSettings() {
        
        Test.setCurrentPageReference(new PageReference('Page.STTG_UserRollupSettings_CTRL'));
        
        //pass the controller into the extension
        STTG_UserRollupSettings_CTRL controller = new STTG_UserRollupSettings_CTRL();
  
        //check settings returns a null pagereference
        PageReference samePage = controller.checkSettings();
        system.assertEquals(samePage, null);
        
        //kickoff a new rollup
        controller.startBuild();
        
        //call the major getter methods
        list<SelectOption> oppyList = controller.getSourceFields();
        controller.activeUDR.SourceField = 'Amount';
        
        list<SelectOption> operatorList = controller.getValidOperators();
        system.assert(operatorList.size() == 4);
        
        controller.activeUDR.SourceField = 'CloseDate';
        operatorList = controller.getValidOperators();
        system.assert(operatorList.size() == 2);
        
        controller.activeUDR.Operation = 'MAX';
                
        list<SelectOption> targetObjectList = controller.getTargetObjects();
        system.assertEquals(targetObjectList.size(), 3);
        
        controller.activeUDR.TargetObject = 'Account';
        
        list<SelectOption> targetFieldList = controller.getTargetFields();
               
        //change target object to test other options        
        controller.activeUDR.TargetObject = 'npo02__Household__c';
        targetFieldList = controller.getTargetFields();
        
        controller.activeUDR.TargetObject = 'Contact';
        targetFieldList = controller.getTargetFields();
        controller.activeUDR.TargetField = 'Birthdate';
        controller.activeUDR.save();
        //load a UDR
        controller.activeUDR.loadMe();        
        
        //run through the loop with a newly inserted UDR
        targetFieldList = controller.getTargetFields();
        
        //existing invalid rollups will cause test failure
        boolean isValid = controller.userRollupsValid();
        system.assertEquals(isValid, true);
        system.assertEquals(controller.activeUDR.getisValid(), true);
        list<STTG_UserRollupSettings_CTRL.UDR> udrlist = controller.getudrList();
        system.assert(udrList.size() > 0);        
        
        //test clearing the three different lists
        controller.clearForTargetObject();
        system.assert(controller.activeUDR.TargetField == null);
        controller.clearForOperation();
        system.assert(controller.activeUDR.TargetObject == null);
        controller.clearForSourceField();
        system.assert(controller.activeUDR.Operation == null);
        
        controller.cancel();
        system.assertEquals(null, controller.activeUDR);
        
        //generate a new one so we can call its delete sequence
        controller.startBuild();
        //delete it
        controller.activeUDR.deleteMe();
        
        //call the other UDR contructor
        STTG_UserRollupSettings_CTRL.UDR u = new STTG_UserRollupSettings_CTRL.UDR('', '', '', '', controller);
                
        //insert invalid rollup to test error handling methods
        User_Rollup_Field_Settings__c badurfs = new User_Rollup_Field_Settings__c(
        Name = 'Invalid Test Rollup',
        npo02__Target_Field__c = 'InvalidTargetField__test',
        npo02__Source_Field__c = 'InvalidSourceField__test',
        npo02__Object_Name__c = 'Account',
        npo02__Field_Action__c = 'TEST'         
        );
        
        insert badurfs;
        
        isValid = controller.userRollupsValid();
        system.assertEquals(false, isValid);
        PageReference pr = controller.checkSettings();        
        
        //exercise household code
        User_Rollup_Field_Settings__c HHurfs = new User_Rollup_Field_Settings__c(
        Name = 'Household Test Rollup',
        npo02__Target_Field__c = 'lastoppamount__c',
        npo02__Source_Field__c = 'Amount',
        npo02__Object_Name__c = 'npo02__Household__c',
        npo02__Field_Action__c = 'MAX'         
        );
        
        insert HHurfs; 
                
        isValid = controller.userRollupsValid();
        system.assertEquals(false, isValid);
            
        User_Rollup_Field_Settings__c badobject = new User_Rollup_Field_Settings__c(
        Name = 'Invalid Object Rollup',
        npo02__Target_Field__c = 'InvalidTargetField__test',
        npo02__Source_Field__c = 'InvalidSourceField__test',
        npo02__Object_Name__c = 'BadAccount',
        npo02__Field_Action__c = 'TEST'
        );
        
        insert badobject;
        
        isValid = controller.userRollupsValid();
        system.assertEquals(false, isValid);
        
    }

}