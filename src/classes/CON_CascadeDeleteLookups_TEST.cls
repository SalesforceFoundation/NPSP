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
* @group Cascade Delete
* @description Tests for cascade delete of Contacts
*/
@isTest
private class CON_CascadeDeleteLookups_TEST {

    /*********************************************************************************************************
    * @description Deletes contact and verifies it does not cascade delete the Relationships
    * Verifies results.
    */
    static testMethod void testContactCascadeDelete(){
        Integer maxRecords = 1;

        List<Contact> contacts = CDL_CascadeDeleteLookups_TEST.buildContacts(maxRecords);
        insert contacts;

        List<npe4__Relationship__c> relationships = CDL_CascadeDeleteLookups_TEST.buildRelationships(contacts);
        insert relationships;

        Test.startTest();
        delete contacts;
        Test.stopTest();

        List<Error__c> errors = CDL_CascadeDeleteLookups_TEST.getErrors();
        System.assertEquals(0, errors.size(), errors);

        List<npe4__Relationship__c> deletedRelationships = CDL_CascadeDeleteLookups_TEST.getDeletedRelationships();
        System.assertEquals(relationships.size() * 2, deletedRelationships.size(), 'Both relationships should be deleted when the Contact is deleted.');

        undelete contacts;

        List<npe4__Relationship__c> undeletedRelationships = CDL_CascadeDeleteLookups_TEST.getNonDeletedRelationships();
        System.assertEquals(deletedRelationships.size(), undeletedRelationships.size(), 'Both relationships should be undeleted when the Contact is undeleted.');
    }

    /*********************************************************************************************************
    * @description Verifies that the losing contact in a merge operation doesn't get child records cascade deleted.
    */
    static testMethod void testContactMergeNoCascade(){
        List<Contact> contacts = CDL_CascadeDeleteLookups_TEST.buildContacts(2);
        insert contacts;

        List<npe4__Relationship__c> relationships = CDL_CascadeDeleteLookups_TEST.buildRelationships(contacts);
        insert relationships;

        merge contacts[0] contacts[1];

        List<Error__c> errors = CDL_CascadeDeleteLookups_TEST.getErrors();
        System.assertEquals(0, errors.size(), errors);

        List<npe4__Relationship__c> deletedRelationships = CDL_CascadeDeleteLookups_TEST.getDeletedRelationships();
        System.assertEquals(0, deletedRelationships.size(), 'Relationships should not be deleted as the result of losing a merge.');
    }
}