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
 * @description Cascade deletion extension for Campaign object.
 */
public with sharing class CAM_CascadeDeleteLookups_TDTM extends CDL_CascadeDeleteLookups_TDTM {

    /*******************************************************************************************************
    * @description Gets the deleted Campaigns CascadeDeleteLoader Object. 
    * @return CDL_CascadeDeleteLookups.CascadeDeleteLoader.
    ********************************************************************************************************/
    protected override CDL_CascadeDeleteLookups.CascadeDeleteLoader getCascadeDeleteLoader() {
        return new CascadeDeleteLoader();
    }

    /*******************************************************************************************************
    * @description Gets the undeleted Campaigns CascadeUndeleteLoader Object.
    * @return CDL_CascadeDeleteLookups.CascadeUndeleteLoader.
    ********************************************************************************************************/
    protected override CDL_CascadeDeleteLookups.CascadeUndeleteLoader getCascadeUndeleteLoader() {
        return new CascadeUndeleteLoader();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the deleted Campaigns.
    ********************************************************************************************************/
    class CascadeDeleteLoader implements CDL_CascadeDeleteLookups.CascadeDeleteLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the related Allocations of the deleted Campaigns.
        * @param Set<Id> The Ids of the deleted Campaigns.
        * @return List<Allocation__c> Deleted Campaigns' Allocations.
        ********************************************************************************************************/
        public List<Allocation__c> load(Set<Id> campaignIds) {
            return [
                SELECT Campaign__c
                FROM Allocation__c
                WHERE Campaign__c IN :campaignIds
            ];
        }
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the undeleted Campaigns.
    ********************************************************************************************************/
    class CascadeUndeleteLoader implements CDL_CascadeDeleteLookups.CascadeUndeleteLoader {

        /*******************************************************************************************************
        * @description Retrieves the related Allocations of the undeleted Campaigns.
        * @param Set<Id> The Ids of the undeleted Campaigns.
        * @return List<Allocation__c> Undeleted Campaigns' Allocations.
        ********************************************************************************************************/
        public List<Allocation__c> load(Set<Id> campaignIds) {
            return [
                SELECT Campaign__c
                FROM Allocation__c
                WHERE Campaign__c IN :campaignIds
                AND IsDeleted = TRUE
                ALL ROWS
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the next children records group to be undeleted. In this case, there is no other
        * group of children records to undelete after Allocations undeletion.
        * @return CDL_CascadeDeleteLookups.CascadeUndeleteLoader.
        ********************************************************************************************************/
        public CDL_CascadeDeleteLookups.CascadeUndeleteLoader next() {
            return null;
        }
    }
}