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

        return ((val != null) && (val.trim().length() > 0)) ? val : TRIBUTE_SINGLE_VAL;
    }

    public static String getMultipleTributesSettingLocalized() {
        
        Map<String, String> mtValToLocalized = new Map<String, String> {
            TRIBUTE_SINGLE_VAL => Label.stgMultipleTributesSingleOpp,
            TRIBUTE_MIXED_VAL => Label.stgMultipleTributesFlexible,
            TRIBUTE_MULTIPLE_VAL => Label.stgMultipleTributesLimited
        };        
        
        return mtValToLocalized.get(getMultipleTributesSetting());

    }

    public static boolean isMultipleTributesSingle() {
        return TRIBUTE_SINGLE_VAL.equalsIgnoreCase(getMultipleTributesSetting());
    }

    public static boolean isMultipleTributesFlexible() {
        return TRIBUTE_MIXED_VAL.equalsIgnoreCase(getMultipleTributesSetting());
    }
    
    public static boolean isMultipleTributesLimited() {
        return TRIBUTE_MULTIPLE_VAL.equalsIgnoreCase(getMultipleTributesSetting());
    }

    private static npe01__Contacts_And_Orgs_Settings__c getSettings() {
        if (settings == null) {
            settings = UTIL_CustomSettingsFacade.getContactsSettings();
        }

        return settings;
    }

}