/*
    Copyright (c) 2021, Salesforce.org
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
* @date 2021
* @group Settings
* @description Test class for STG_PanelRDBatch_CTRL
*/
@isTest
private with sharing class STG_PanelRDBatch_CTRL_TEST {
    /**
    * @description Validate that the User has the proper permissions to the Opp and RD object
    * during page load
    */
    @isTest
    private static void shouldAllowAccessToUser() {
        User adminUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR);

        System.runAs(adminUser) {
            STG_PanelRDBatch_CTRL controller = new STG_PanelRDBatch_CTRL();
            Boolean hasAccess = controller.getHasAccess();

            System.assertEquals(true, hasAccess, 'The access check should return true if the user has update ' +
                'access to Opp and Recurring Donation object');
        }
    }

    /**
    * @description Validate that the method returns false if User does not have Update permissions to Opp and RD object
    */
    @isTest
    private static void shouldNotAllowAccessToReadOnlyUser() {
        User standardUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_READ_ONLY);

        System.runAs(standardUser) {
            STG_PanelRDBatch_CTRL controller = new STG_PanelRDBatch_CTRL();
            Boolean hasAccess = controller.getHasAccess();

            System.assertEquals(false, hasAccess, 'The access check should return false if the user does NOT have ' +
                'update access to the Opp and RD object');
        }
    }
}
