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
    * @description Gets the ChildrenLoader Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.ChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.ChildrenLoader getDeletionChildrenLoader() {
        return new CampaignDeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Gets the ChildrenLoader Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.ChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.ChildrenLoader getUndeletionChildrenLoader() {
        return new CampaignUndeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the Campaign being deleted
    ********************************************************************************************************/
    class CampaignDeletionChildrenLoader implements CascadeDeleteLookupsDomain.ChildrenLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the children of the Campaign being deleted
        * @return List<Allocation__c> Deleted Campaign's Allocations
        ********************************************************************************************************/
        public List<Allocation__c> loadChildren(Set<Id> parentsIds) {
            return [
                SELECT Campaign__c
                FROM Allocation__c
                WHERE Campaign__c IN :parentsIds
            ];
        }
    }

    /*******************************************************************************************************
    * @description Retrieves the children of the Campaign being undeleted
    ********************************************************************************************************/
    class CampaignUndeletionChildrenLoader implements CascadeDeleteLookupsDomain.ChildrenLoader {

        /*******************************************************************************************************
        * @description Retrieves the children of the Campaign being undeleted
        * @return List<Allocation__c> Undeleted Campaign's Allocations
        ********************************************************************************************************/
        public List<Allocation__c> loadChildren(Set<Id> parentsIds) {
            return [
                SELECT Campaign__c
                FROM Allocation__c
                WHERE Campaign__c IN :parentsIds
                AND IsDeleted = TRUE
                ALL ROWS
            ];
        }
    }
}