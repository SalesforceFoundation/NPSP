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
* @description Org Settings class in NPSP.
*/
public inherited sharing class OrgConfig {

    public Boolean isPersonAccountsEnabled() {
        return UTIL_Describe.isValidField(String.valueOf(Account.SObjectType), 'isPersonAccount');
    }

    /*******************************************************************************************************
    * @description specifies whether state and country picklists are enabled in this org.
    * @return true if enabled
    */
    private static Boolean isStateCountryPicklistsEnabled {
        get {
            if (isStateCountryPicklistsEnabled == null) {
                isStateCountryPicklistsEnabled = stateAndCountryPicklistsEnabled();
            }
            return isStateCountryPicklistsEnabled;
        }
        private set;
    }

    public Boolean isStateCountryPicklistsEnabled() {
        return isStateCountryPicklistsEnabled;
    }

    private static Boolean stateAndCountryPicklistsEnabled() {
        fflib_SObjectDescribe accountDescribe =
                fflib_SObjectDescribe.getDescribe(Account.SObjectType);
        SObjectField sObjectField = accountDescribe.getField('BillingStateCode');
        return sObjectField != null;
    }
}