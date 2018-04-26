/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Utilities
* @description Unit test for the Custom Metadata Type api class
*/
@isTest(IsParallel=true)
private class CMT_MetadataAPI_TEST {

    static testMethod void test_cmt_api() {
        CMT_MetadataAPI.upsertCustomMetadata(CRLP_RollupCMT.MetadataObject.Filter_Rule, 'Rule_1', 'Rule 1: OCR.Role',
                new Map<String,Object>{
                        'Filter_Group__c' => 'm016A000000YXdG',
                        'Operation__c' => 'Equals',
                        'Constant__c' => 'Solicitor',
                        'Object__c' => SObjectType.OpportunityContactRole.getName(),
                        'Field__c' => SObjectType.OpportunityContactRole.Fields.Role.getName()
                });

        CMT_MetadataAPI.deployMetadata(UserInfo.getUserId(), CMT_MetadataAPI.cmtUpsertQueue);
        CMT_MetadataAPI.deleteCustomMetadataTypeRecord(CRLP_RollupCMT.MetadataObject.Filter_Group, 'SomeName');

        // Construct our callback class
        CMT_MetadataAPI.MetadataCallBack callback = new CMT_MetadataAPI.MetadataCallBack('Test');

        // Construct a dummy Context
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();

        // Call the handleResult() method of our main Callback with our dummy context var
        callback.handleResult(null, context);
    }


    /* @description DeployCallbackContext subclass for testing that returns myJobId */
    public class TestingDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override Id getCallbackJobId() {
            return '000000000122345';
        }
    }

}