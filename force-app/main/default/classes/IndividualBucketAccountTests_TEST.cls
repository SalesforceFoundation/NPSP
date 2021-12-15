/*
    Copyright (c) 2021 Salesforce.org
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
* @description Organization Account tests in NPSP.
*/
@IsTest
private class IndividualBucketAccountTests_TEST {

    @IsTest
    static void delete_one_contact_from_bucket_account_should_not_rename_account() {
        // Arrange: GIVEN the App is configured to use the Individual Bucket Account
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c
                        (npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR));

        // Arrange: AND the Bucket Account has multiple child Contacts
        Contact orgContact1 = new Contact(LastName = 'testCon1');
        Contact orgContact2 = new Contact(LastName = 'testCon2');
        insert new List<Contact>{
                orgContact1, orgContact2
        };

        // Act: WHEN one of the Contacts is deleted
        Test.startTest();
        delete orgContact2;
        Test.stopTest();

        // Assert: THEN the Individual Bucket Account should not be renamed
        IndividualBucketAccount bucketAccount = IndividualBucketAccount.getInstance();
        System.assertEquals(
                CAO_Constants.BUCKET_ACCOUNT_NAME,
                bucketAccount.name(),
                'The name of the Bucket Account should not change after deleting a Contact.');
    }

    @IsTest
    static void instance_name_property_is_null_when_account_not_yet_created() {
        // Arrange: GIVEN the Bucket Account does not yet exist
        // Act: WHEN the name property is referenced
        String bucketAccountName = IndividualBucketAccount.getInstance().name();

        // Assert: THEN the name is null and a Null Pointer Exception is not encountered
        System.assertEquals(null, bucketAccountName,
                'The name of the Bucket Account should be null since the Bucket Account ' +
                        'does not yet exist.');
    }
}