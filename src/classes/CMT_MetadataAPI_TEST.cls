/*
    Copyright (c) 2017, Salesforce.org
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
* @group Utilities
* @description Unit test for the Custom Metadata Type api class
*/
@isTest
private class CMT_MetadataAPI_TEST {

    static testMethod void test_cmt_api() {
        CMT_MetadataAPI.upsertCustomMetadata(CMT_MetadataAPI.MetadataObject.Filter_Rule, 'Rule_1', 'Rule 1: OCR.Role',
                new Map<String,Object>{
                        'Filter_Group__c' => 'm016A000000YXdG',
                        'Operation__c' => 'Equals',
                        'Constant__c' => 'Solicitor',
                        'Object__c' => SObjectType.OpportunityContactRole.getName(),
                        'Field__c' => SObjectType.OpportunityContactRole.Fields.Role.getName()
                });

        CMT_MetadataAPI.commitPendingOperations();
        CMT_MetadataAPI.deleteCustomMetadataTypeRecord(CMT_MetadataAPI.MetadataObject.Filter_Group, 'SomeName');

        CMT_MetadataAPI.MetadataCallBack callback = new CMT_MetadataAPI.MetadataCallBack();
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();
        callback.handleResult(null, context);
    }


    // DeployCallbackContext subclass for testing that returns myJobId
    // This appears to be not available yet, even though the docs say that this needs to be extended.
    // No new features to the Metadata Api are due in Winter '18, so the fix for this might be in until
    // later in 2018.
    /*public class TestingDeployResult extends Metadata.DeployResult {
        public override Metadata.DeployStatus getStatus() {
            return Metadata.DeployStatus.Succeeded;
        }
    }*/


    // DeployCallbackContext subclass for testing that returns myJobId
    public class TestingDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override Id getCallbackJobId() {
            return '000000000122345';
        }
    }

}