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
* @group
* @group-content
* @description Provides an adapter for Advancement package to be able to inject customizations into NPSP and provide API to inject to other project.
**/

global virtual with sharing class Advancement_Adapter {

    /**
     * @description To be called by the NPSP TDTM trigger dispatcher. Advancement will disable some NPSP trigger handlers records (since they conflict with HEDA version)
     * and return the rest
     *
     * @return List<Trigger_Handler__c> The TDTM configuration.
     */
    global virtual List<Trigger_Handler__c> getDefaultTdtmConfigNpspRecords(List<Trigger_Handler__c> listTH) {
        return TDTM_Config_API.getDefaultRecords();
    }

    /**
     * @description Since Advancement will disable some NPSP trigger handler class, we need to fill in gap in HEDA.
     * Expose this API for Advancement to inject the rollup functionality into HEDA code base
     *
     * @return none
     */
    global static void rollupAccounts(list<Id> listAccountId) {
        ACCT_IndividualAccounts_TDTM.rollupAccounts(listAccountId);
    }
}