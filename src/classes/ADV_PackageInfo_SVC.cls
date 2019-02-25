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
* @group TDTM
* @group-content ../../ApexDocContent/TDTM.htm
* @description Provides the Advancement Information to NPSP class.
**/
public with sharing class ADV_PackageInfo_SVC {
    /*******************************************************************************************************
    * @description  The boolean value to determine if Adv project is installed.
    *******************************************************************************************************/
    private static Boolean useAdv = false;

    /*******************************************************************************************************
    * @description  The adapter class from Adv to override the default behavior of ADV_Adapter.
    *******************************************************************************************************/
    private static ADV_Adapter apiNPSP = null;

    /*******************************************************************************************************
    * @description  The boolean value to determine if the setup is called before.
    *******************************************************************************************************/
    private static Boolean setupCalled = false;

    /*******************************************************************************************************
    * @description Setup the attributes of the class.
    * @return void
    *******************************************************************************************************/
    private static void setup() {

        //Check if setup() is being called. If yes, just return
        if (setupCalled) {
            return;
        }

        npe01__Contacts_And_Orgs_Settings__c orgSetting = UTIL_CustomSettingsFacade.getOrgContactsSettings();

        //Determine if the current Adv code is inside a package
        Boolean isManaged = false;

        if (String.isBlank(orgSetting.Advancement_Namespace__c)) {
            orgSetting.Advancement_Namespace__c = String.valueOf(npe01__Contacts_And_Orgs_Settings__c.Advancement_Namespace__c.getDescribe().getDefaultValueFormula()).remove('\"');
        }

        //Check if GEM is installed
        List<String> settingsObjs = new List<String> {'Advancement_Setting__mdt', 'GEM_API_Settings__mdt'};
        List<String> useGEMFields = new List<String> {'Use_Advancement__c', 'Use_GEM__c'};

        boolean found = false;

        Integer i=0;
        while (!found && i < settingsObjs.size()) {
            try { // With Namespace
                Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(new String[]{orgSetting.Advancement_Namespace__c + '__' + settingsObjs[i]});
                isManaged = true;
                found = true;
            } catch (Exception e) {
                try { // Without Namespace
                    Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(new String[]{settingsObjs[i]});
                    found = true;
                } catch (Exception ex) {
                    i++;
                }
            }
        }

        if (!found) {
            setupCalled = true;
            return;
        }

        String gemAPISettingsObj = settingsObjs[i];
        String useGEMField= useGEMFields[i];

        //If Adv is installed, we need to throw exception if Adv is not configured correctly
        Boolean hasConfigError = true;

        String nsPrefixOrBlank = (isManaged) ?  String.escapeSingleQuotes(orgSetting.Advancement_Namespace__c) + '__' : '';

        String useAdvStr = nsPrefixOrBlank + useGEMField;
        String apiNpspClassStr = nsPrefixOrBlank + 'API_NPSP_Class__c';

        String advSettingQuery = 'select ' + useAdvStr + ', ' + apiNpspClassStr + ' from ' + nsPrefixOrBlank + gemAPISettingsObj;

        List<SObject> advSettings = Database.query(advSettingQuery);
        if (advSettings != null && advSettings.size() > 0) {
            useAdv = (Boolean)advSettings[0].get(useAdvStr);
            if (useAdv) {
                String apiNPSPClass = (String)advSettings[0].get(apiNpspClassStr);
                if (String.isNotBlank(apiNPSPClass)) {
                    if (isManaged == true) {
                        apiNPSPClass = String.escapeSingleQuotes(orgSetting.Advancement_Namespace__c) + '.' + apiNPSPClass;
                    }
                    Type classType = Type.forName(apiNPSPClass);
                    if (classType != null) {
                        Object classInstance = classType.newInstance();
                        if (classInstance instanceof ADV_Adapter) {
                            apiNPSP = (ADV_Adapter) classInstance;
                            hasConfigError = false;
                        }
                    }
                }
            } else {
                hasConfigError = false;
            }
        }

        setupCalled = true;

        if(hasConfigError) {
            throw new ADVException(Label.giftProcessingConfigException);
        }
    }

    /*******************************************************************************************************
    * @description The method for other class to determine if Adv is installed or not.
    * @return useAdv The boolean value to determine if Adv project is installed.
    *******************************************************************************************************/
    public static Boolean useAdv() {
        setup();
        return useAdv;
    }

    /*******************************************************************************************************
    * @description The method for other class to get the API_NPSP class instance
    * @return ADV_Adapter The adapter class from Adv to override the default behavior of
    * ADV_Adapter
    *******************************************************************************************************/
    public static ADV_Adapter getApiNPSP() {
        setup();
        return apiNPSP;
    }

    /*******************************************************************************************************
    * @description This is the expection class for ADV_PackageInfo_SVC class
    ********************************************************************************************************/
    private class ADVException extends Exception{}
}