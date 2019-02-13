/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group BGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Unit Tests for the BGE Utility class.
*/

@isTest
private with sharing class BGE_BatchGiftEntry_UTIL_TEST {

    private static UTIL_Mocks.PermissionsMock mockPerms = new UTIL_Mocks.PermissionsMock();

    /*********************************************************************************************************
    * @description Tests truncateList()
    */
    @isTest
    static void testTruncateList() {
        List<String> fruits = new List<String> { 'apple', 'banana', 'pear', 'orange' };
        System.assertEquals('apple, banana, pear, orange', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 5));
        System.assertEquals('apple, banana, pear, orange', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 4));
        System.assertEquals('apple, banana, pear ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 3));
        System.assertEquals('apple, banana ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 2));
        System.assertEquals('apple ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 1));
    }

    /*********************************************************************************************************
    * @description Tests handleMissingPermissions() methods
    */
    @isTest
    static void testHandleMissingPermissions() {
        List<DescribeFieldResult> dfrs = new List<DescribeFieldResult>();
        dfrs.add(UTIL_Describe.getFieldDescribe('Account','Name'));
        dfrs.add(UTIL_Describe.getFieldDescribe('Account','CreatedById'));
        String expectedErrorMsg = Label.bgeFLSError + ' [Account Name, Created By ID]';

        try {
            BGE_BatchGiftEntry_UTIL.handleMissingPermissions(dfrs);
        } catch (AuraHandledException ex) {
            System.assertEquals(expectedErrorMsg, ex.getMessage());
        }
    }

    /*********************************************************************************************************
    * @description Tests checkFieldPermissionsNeededForBatch() methods
    */
    @isTest
    static void testCheckFieldPermissionsNeededForBatch() {
        Boolean hasError = false;


        mockPerms.hasUpdate = false;
        BGE_BatchGiftEntry_UTIL bgeUtil = new BGE_BatchGiftEntry_UTIL();
        bgeUtil.perms = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class, mockPerms);
        try {
            bgeUtil.checkFieldPermissionsNeededForBatchInstance();

            System.assertEquals(UTIL_Describe.getSObjectType(UTIL_Namespace.StrTokenNSPrefix('DataImport__c')), 
                mockPerms.updateSObjType);
        } catch (AuraHandledException ex) {
            hasError = true;
            String errorMsg = ex.getMessage();
            System.assert(errorMsg.contains(Label.bgeFLSError), 'Only perms errors should be thrown.');
        } catch (Exception ex) {
            hasError = true;
            System.assert(false, 'Unhandled exception thrown.');
        }
    }

}