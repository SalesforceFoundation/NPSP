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
* @group Elevate
* @description Utility methods to determine the Payment Integration Services status
*/
public class PS_IntegrationService_UTIL {

    /**
    * @description Defined Custom Permission that will be used to identify a User capable of modifying
    * Recurring Donation records that are associated with Elevate
    */
    private final Set<String> elevateCustomPermissions = new Set<String>{
        'ElevateIntegrationUser'
    };

    /**
    * @description The Elevate Payment Services integration is considered "enabled" (for now) when there
    * is at least a single record in the protected PaymentServicesConfiguration object
    */
    private Boolean elevateIntegrationEnabled {
        get {
            if (elevateIntegrationEnabled == null) {
                Integer configCount = Database.countQuery('SELECT Count() FROM Payment_Services_Configuration__c');
                elevateIntegrationEnabled = (configCount == 0);
            }
            return elevateIntegrationEnabled;
        } set;
    }

    /**
    * @description Returns true if the Payment Services-NPSP Integration is enabled in the current org.
    * @return Boolean
    */
    public Boolean isIntegrationEnabled() {
        return elevateIntegrationEnabled;
    }

    /**
    * @description Returns true if the current user has the appropriate permissions to modify Elevate
    * records (i.e., they are considered an integration user).
    * @return Boolean
    */
    public Boolean hasIntegrationPermissions() {
        Boolean hasPerm = true;
        for (String perm : elevateCustomPermissions) {
            hasPerm = hasPerm && FeatureManagement.checkPermission(perm);
        }
        return hasPerm;
    }
}