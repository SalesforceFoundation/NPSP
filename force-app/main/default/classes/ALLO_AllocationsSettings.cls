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
* @group Allocations
* @description Class to work with Allocations Settings
*/
public inherited sharing class ALLO_AllocationsSettings {

    /** @description Static instance of this class */
    private static ALLO_AllocationsSettings settings;

    /** @description Org's Allocations Settings */
    private Allocations_Settings__c allocationsSettings {
        private get {
            if (allocationsSettings == null) {
                allocationsSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();
            }
            return allocationsSettings;
        }
        private set;
    }

    /**
     * @description Private constructor to prevent direct instantiation
     * @return constructed instance of class
     */
    private ALLO_AllocationsSettings() {
    }

    /**
     * @description Factory method to get the settings.  Only creates a single instance, and returns that if
     *              already instantiated
     * @return instance of ALLO_AllocationsSettings
     */
    public static ALLO_AllocationsSettings getSettings() {
        if (settings == null) {
            settings = new ALLO_AllocationsSettings();
        }
        return settings;
    }

    /**
     * @description Determines if Default Allocations are enabled for the org
     * @return Boolean true, if Default Allocations are enabled
     */
    public Boolean isDefaultAllocationsEnabled() {
        return allocationsSettings.Default_Allocations_Enabled__c == true;
    }

    /**
     * @description Determines if Payment Allocations are enabled for the org
     * @return Boolean true, if Payment Allocations are enabled
     */
    public Boolean isPaymentAllocationsEnabled() {
        return allocationsSettings.Payment_Allocations_Enabled__c == true;
    }

    /**
     * @description The Default Allocations Id, if set for the org
     * @return Id Id of the General_Accounting_Unit__c defined as the Default Allocation if Default Allocations are
     *         Enabled and one is configured
     */
    public Id getDefaultAllocationsId() {
        return (isDefaultAllocationsEnabled()) ? allocationsSettings.Default__c : null;
    }

    /**
     * @description Returns a list of configuration problems, if any.  If the List is empty, there are no
     *              configuration problems.
     * @return List<String> List of configuration problems, if any
     */
    public List<String> validatePaymentAllocationsConfiguration() {
        List<String> problems = new List<String>();
        if (!isPaymentAllocationsEnabled()) {
            problems.add(System.Label.alloPaymentNotEnabled);
        }
        if (!isDefaultAllocationsEnabled()) {
            problems.add(System.Label.alloDefaultNotEnabled);
        }

        if (allocationsSettings.Default__c == null) {
            problems.add(System.Label.alloDefaultGAUMissing);
        } else {
            List<General_Accounting_Unit__c> defaultGAU = [select Id, Active__c, Name from General_Accounting_Unit__c where Id = :allocationsSettings.Default__c];
            if (defaultGAU.size() < 1) {
                problems.add(System.Label.alloDefaultGAUMissing);
            } else if (!defaultGAU[0].Active__c) {
                problems.add(System.Label.alloDefaultGAUNotActive.replace('{0}', defaultGAU[0].Name));
            }
        }

        return problems;
    }
}