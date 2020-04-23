/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Determines the Elevate Payment Integration Services status and permissions
*/
public with sharing class PS_IntegrationServiceConfig {

    /**
    * @description Determines if the Elevate integration service is configured and enabled.
    * The Elevate Payment Services integration is considered "enabled" (for now) when there
    * is at least a single record in the protected Payment Services Configuration object
    * @return Boolean
    */
    private Boolean isEnabled {
        get {
            if (isEnabled == null) {
                //Integer configCount = Database.countQuery('SELECT Count() FROM Payment_Services_Configuration__c');
                Integer configCount = 0;//TODO: hard-coded, disable the integration service until full implementation
                isEnabled = configCount > 0;
            }
            return isEnabled;
        }
        set;
    }

    /**
    * @description Returns the Elevate integration service enablement status
    * @return Boolean
    */
    public Boolean isIntegrationEnabled() {
        return isEnabled;
    }

    /**
    * @description Determines if the current user has the appropriate permissions to modify Elevate records
    * @return Boolean
    */
    public Boolean hasIntegrationPermissions() {
        // If the integration service is not enabled, user does not have the integration permissions
        if (!isEnabled) {
            return false;
        }

        return false;//TODO: hard-coded until the full implementation
    }

}
