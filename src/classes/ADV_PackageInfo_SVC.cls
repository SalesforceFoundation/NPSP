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

        //Check if Advancement is installed and Licensed
        Boolean isUserLicensed = false;

        try {
            //If the Advancement is not installed, then it will throw TypeException. Otherwise, it will return True/False
            isUserLicensed = UserInfo.isCurrentUserLicensed('adv1');
        } catch (Exception e) {
            // Advancement not installed. Just Return
            setupCalled = true;
            return;
        }

        //If Adv is installed, we need to throw exception if Adv is not configured correctly
        Boolean hasConfigError = true;

        if(isUserLicensed) {
            List<SObject> advSettings = Database.query('select adv1__Use_Advancement__c, adv1__API_NPSP_Class__c from adv1__Advancement_Setting__mdt');
            if(advSettings != null && advSettings.size() > 0) {
                useAdv = (Boolean)advSettings[0].get('adv1__Use_Advancement__c');
                if(useAdv) {
                    String apiNPSPClass = (String)advSettings[0].get('adv1__API_NPSP_Class__c');
                    if(String.isNotBlank(apiNPSPClass)) {
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