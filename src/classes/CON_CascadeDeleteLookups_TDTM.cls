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
 * @group Cascade Delete
 * @description Cascade deletion extension for Contact object.
 */
public with sharing class CON_CascadeDeleteLookups_TDTM extends CDL_CascadeDeleteLookups_TDTM {

    /*******************************************************************************************************
    * @description Gets the deleted Contacts CascadeDeleteLoader Object. 
    * @return CDL_CascadeDeleteLookups.CascadeDeleteLoader.
    ********************************************************************************************************/
    protected override CDL_CascadeDeleteLookups.CascadeDeleteLoader getCascadeDeleteLoader() {
        return new CascadeDeleteLoader();
    }

    /*******************************************************************************************************
    * @description Gets the undeleted Contacts CascadeUndeleteLoader Object.
    * @return CDL_CascadeDeleteLookups.CascadeUndeleteLoader.
    ********************************************************************************************************/
    protected override CDL_CascadeDeleteLookups.CascadeUndeleteLoader getCascadeUndeleteLoader() {
        return new CascadeUndeleteLoader();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the deleted Contacts.
    ********************************************************************************************************/
    class CascadeDeleteLoader implements CDL_CascadeDeleteLookups.CascadeDeleteLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the related Relationships of the deleted Contacts.
        * @param Set<Id> The Ids of the deleted Contacts.
        * @return List<npe4__Relationship__c> Deleted Contacts' Relationships.
        ********************************************************************************************************/
        public List<npe4__Relationship__c> load(Set<Id> contactIds) {
            List<SObject> reciprocalRelationships = [
                SELECT Id
                FROM npe4__Relationship__c
                WHERE npe4__Contact__c IN :contactIds
            ];

            return [
                SELECT Name
                FROM npe4__Relationship__c
                WHERE npe4__ReciprocalRelationship__c IN :reciprocalRelationships
            ];
        }
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the undeleted Contacts.
    ********************************************************************************************************/
    class CascadeUndeleteLoader implements CDL_CascadeDeleteLookups.CascadeUndeleteLoader {

        /*******************************************************************************************************
        * @description Retrieves the Relationships of the undeleted Contacts.
        * @param Set<Id> The Ids of the undeleted Contacts.
        * @return List<npe4__Relationship__c> Undeleted Contacts' Relationships.
        ********************************************************************************************************/
        public List<npe4__Relationship__c> load(Set<Id> contactIds) {
            List<npe4__Relationship__c> reciprocalRelationships = [
                SELECT Id
                FROM npe4__Relationship__c
                WHERE npe4__Contact__c IN :contactIds
            ];

            return [
                SELECT Name
                FROM npe4__Relationship__c
                WHERE npe4__ReciprocalRelationship__c IN :reciprocalRelationships
                AND IsDeleted = TRUE
                ALL ROWS
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the next children records group to be undeleted. In this case, there is no other
        * group of children records to undelete after Relationships undeletion.
        * @return CDL_CascadeDeleteLookups.CascadeUndeleteLoader
        ********************************************************************************************************/
        public CDL_CascadeDeleteLookups.CascadeUndeleteLoader next() {
            return null;
        }
    }
}