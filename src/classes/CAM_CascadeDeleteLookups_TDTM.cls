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
 * @description Cascade deletion extension for Campaign object.
 */
public with sharing class CAM_CascadeDeleteLookups_TDTM extends CascadeDeleteLookups_TDTM {

    /*******************************************************************************************************
    * @description Gets the deleted Campaigns ChildrenLoader Object. 
    * @return CascadeDeleteLookupsDomain.DeleteChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.DeleteChildrenLoader getDeletionChildrenLoader() {
        return new CampaignDeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Gets the undeleted Campaigns ChildrenLoader Object.
    * @return CascadeDeleteLookupsDomain.UndeleteChildrenLoader.
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.UndeleteChildrenLoader getUndeletionChildrenLoader() {
        return new CampaignUndeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the Campaigns being deleted.
    ********************************************************************************************************/
    class CampaignDeletionChildrenLoader implements CascadeDeleteLookupsDomain.DeleteChildrenLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the related Allocations of the Campaign being deleted.
        * @param Set<Id> The Ids of the deleted Campaigns
        * @return List<Allocation__c> Deleted Campaigns' Allocations.
        ********************************************************************************************************/
        public List<Allocation__c> load(Set<Id> parentsIds) {
            return [
                SELECT Campaign__c
                FROM Allocation__c
                WHERE Campaign__c IN :parentsIds
            ];
        }
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the Campaigns being undeleted
    ********************************************************************************************************/
    class CampaignUndeletionChildrenLoader implements CascadeDeleteLookupsDomain.UndeleteChildrenLoader {

        /*******************************************************************************************************
        * @description Retrieves the related Allocations of the Campaign being undeleted.
        * @param Set<Id> The Ids of the undeleted Campaigns
        * @return List<Allocation__c> Undeleted Campaigns' Allocations.
        ********************************************************************************************************/
        public List<Allocation__c> load(Set<Id> parentsIds) {
            return [
                SELECT Campaign__c
                FROM Allocation__c
                WHERE Campaign__c IN :parentsIds
                AND IsDeleted = TRUE
                ALL ROWS
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the next children records group to be undeleted. In this case, there is no other
        * group of children records to undelete after Allocations undeletion.
        * @return CascadeDeleteLookupsDomain.UndeleteChildrenLoader
        ********************************************************************************************************/
        public CascadeDeleteLookupsDomain.UndeleteChildrenLoader next() {
            return null;
        }
    }
}