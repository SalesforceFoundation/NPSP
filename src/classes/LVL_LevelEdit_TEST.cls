/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Levels
* @description test the controller for the Level Edit/New/Clone override visualforce page
*/

@isTest
private with sharing class LVL_LevelEdit_TEST {
    
    /*******************************************************************************************************
    * @description create a new level from the page
    * verify Level created
    */ 
    static testmethod void testNewLevel() {
        Test.setCurrentPage(Page.LVL_LevelEdit);
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Level__c());
        LVL_LevelEdit_CTRL ctrl = new LVL_LevelEdit_CTRL(stdCtrl);
        ctrl.lvl.Name = 'test level';
        ctrl.lvl.Target__c = 'Contact';
        ctrl.lvl.Source_Field__c = 'npo02__TotalOppAmount__c';
        ctrl.lvl.Level_Field__c = 'npo02__LastMembershipLevel__c';
        
        Test.startTest();
        stdCtrl.save();
        Test.stopTest();
        
        list<Level__c> listLvl = [Select Id, Name, Target__c from Level__c];
        system.assertEquals(1, listLvl.size());
        system.assertEquals('test level', listLvl[0].Name);
    }
    
    /*******************************************************************************************************
    * @description create two new levels from the page
    * verify Level created
    */ 
    static testmethod void testSaveAndNewLevel() {
        Test.setCurrentPage(Page.LVL_LevelEdit);
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Level__c());
        LVL_LevelEdit_CTRL ctrl = new LVL_LevelEdit_CTRL(stdCtrl);
        ctrl.lvl.Name = 'test level1';
        ctrl.lvl.Target__c = 'Contact';
        ctrl.lvl.Source_Field__c = 'npo02__TotalOppAmount__c';
        ctrl.lvl.Level_Field__c = 'npo02__LastMembershipLevel__c';
        ctrl.lvl.Minimum_Amount__c = 100;
        ctrl.lvl.Maximum_Amount__c = 200;
        
        Test.startTest();
        ctrl.saveAndNew();
        ctrl.lvl.Name = 'test level2';
        system.assertEquals(200, ctrl.lvl.Minimum_Amount__c);
        system.assertEquals(null, ctrl.lvl.Maximum_Amount__c);
        stdCtrl.save();
        Test.stopTest();
        
        list<Level__c> listLvl = [Select Id, Name, Target__c from Level__c order by Name];
        system.assertEquals(2, listLvl.size());
        system.assertEquals('test level1', listLvl[0].Name);
        system.assertEquals('test level2', listLvl[1].Name);
    }
    
    /*******************************************************************************************************
    * @description test Target field changes refresh our Source Field and Level Field selectoption lists
    * verify Level created
    */ 
    static testmethod void testTargetFieldChange() {
        Test.setCurrentPage(Page.LVL_LevelEdit);
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Level__c());
        LVL_LevelEdit_CTRL ctrl = new LVL_LevelEdit_CTRL(stdCtrl);
        ctrl.lvl.Name = 'test level';
        ctrl.lvl.Target__c = 'Contact';
        ctrl.lvl.Source_Field__c = 'npo02__TotalOppAmount__c';
        ctrl.lvl.Level_Field__c = 'npo02__LastMembershipLevel__c';
        
        Test.startTest();
        system.assertNotEquals(0, ctrl.listSOSourceFields.size());
        system.assertNotEquals(0, ctrl.listSOLevelFields.size());

        ctrl.lvl.Target__c = null;
        ctrl.targetChanged();
        system.assertEquals(0, ctrl.listSOSourceFields.size());
        system.assertEquals(0, ctrl.listSOLevelFields.size());

        ctrl.lvl.Target__c = 'Account';
        ctrl.targetChanged();
        system.assertNotEquals(0, ctrl.listSOSourceFields.size());
        system.assertNotEquals(0, ctrl.listSOLevelFields.size());
        Test.stopTest();
    }
        
}