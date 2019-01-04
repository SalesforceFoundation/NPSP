/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Tribute
* @group-content ../../ApexDocContent/Tribute.htm
* @description Provides suppporting methods for Multiple Tributes
*/
public class TBU_MultipleTributesSettingsFacade {

    public static final String TRIBUTE_SINGLE_VAL = 'Single';
    public static final String TRIBUTE_MIXED_VAL = 'Mixed';
    public static final String TRIBUTE_MULTIPLE_VAL = 'Multiple';

    private static npe01__Contacts_And_Orgs_Settings__c settings = null;

    /*******************************************************************************************************
    * @description Returns the MultipleTributesSetting, or a default of Single Tribute, if setting value is null;
    * @return Value of Multiple Tributes Setting, or Single if null
    ********************************************************************************************************/
    public static String getMultipleTributesSetting() {
        npe01__Contacts_And_Orgs_Settings__c mtSettings = getSettings();

        String val = (mtSettings != null) ? mtSettings.Multiple_Tributes__c : null;

        return (String.IsBlank(val) ? TRIBUTE_SINGLE_VAL : val);
    }

    /*******************************************************************************************************
    * @description Returns the localized version of the MultipleTributesSetting for display, or null
    * if not found.
    * @return String Display value for Currentl Multiple Tributes Setting, in user's local language
    ********************************************************************************************************/
    public static String getMultipleTributesSettingLocalized() {

        return getMultipleTributesSettingLocalized(getMultipleTributesSetting());
    }

    /*******************************************************************************************************
    * @description Returns the localized version of the display value of the requested tribute settings
    * value, or null if not found.
    * @param tributeSettingVal Value
    * @return String Display value for Currentl Multiple Tributes Setting, in user's local language
    ********************************************************************************************************/
    public static String getMultipleTributesSettingLocalized(String tributeSettingVal) {

        if (tributeSettingVal.equalsIgnoreCase(TRIBUTE_SINGLE_VAL))
                return Label.stgMultipleTributesSingleOpp;
        else if (tributeSettingVal.equalsIgnoreCase(TRIBUTE_MIXED_VAL))
                return Label.stgMultipleTributesFlexible;
        else if (tributeSettingVal.equalsIgnoreCase(TRIBUTE_MULTIPLE_VAL))
                return Label.stgMultipleTributesLimited;
        else
            return null;
    }

    /*******************************************************************************************************
    * @description Boolean indicator indicating if Multiple Tributes is in "Single Tribute Only" mode,
    * where tribute information exists only on the Opportunity.  Single Mode is the default if not value is set
    * @return Boolean True if set to Single Tribute Only mode, false otherwise
    ********************************************************************************************************/
    public static boolean isMultipleTributesSingle() {
        return TRIBUTE_SINGLE_VAL.equalsIgnoreCase(getMultipleTributesSetting());
    }

    /*******************************************************************************************************
    * @description Boolean indicator indicating if Multiple Tributes is in "flexible" mode,
    * where tribute information can exist eitbher as related Tribute records, or on the Opportunity
    * @return Boolean True if set to "flexible" mode, false otherwise
    ********************************************************************************************************/
    public static boolean isMultipleTributesFlexible() {
        return TRIBUTE_MIXED_VAL.equalsIgnoreCase(getMultipleTributesSetting());
    }

    /*******************************************************************************************************
    * @description Boolean indicator indicating if Multiple Tributes is in "multiple tributes only" mode,
    * where tribute information can exist only as related Tribute records
    * @return Boolean True if set to "multiple tributes only" mode, false otherwise
    ********************************************************************************************************/
    public static boolean isMultipleTributesLimited() {
        return TRIBUTE_MULTIPLE_VAL.equalsIgnoreCase(getMultipleTributesSetting());
    }

    /*******************************************************************************************************
    * @description Retrieves NPSP Contact And Orgs Settings via existing
    * UTIL_CustomSettingsFacade.getContactSettings method
    * @return npe01__Contact_And_Orgs_Settings__c populated NPSP Contact And Org Settingsd record
    ********************************************************************************************************/
    private static npe01__Contacts_And_Orgs_Settings__c getSettings() {
        if (settings == null) {
            settings = UTIL_CustomSettingsFacade.getContactsSettings();
        }

        return settings;
    }
}