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
* @description Tests for ADV_Adapter
**/
@isTest
public class ADV_Adapter_TEST {
    /*********************************************************************************************************
    * @description Throw exception if Adv is not installed
    */
    @isTest
    public static void getDefaultTdtmConfigTokensThrowException() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        ADV_Adapter theAdapter = new ADV_Adapter();
        Test.startTest();
        try {
            List<Trigger_Handler__c> triggerHandlers = theAdapter.getDefaultTdtmConfigNpspRecords(null);
            //Add this to make sure it throws exception
            System.assert(false);
        } catch (Exception ex) {
            System.assertEquals(Label.adapterException, ex.getMessage());
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Throw exception if Adv is not installed
    */
    @isTest
    public static void rollupAccountThrowException() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        ADV_Adapter theAdapter = new ADV_Adapter();
        Test.startTest();
        try {
            theAdapter.rollupAccounts(null);
            //Add this to make sure it throws exception
            System.assert(false);
        } catch (Exception ex) {
            System.assertEquals(Label.adapterException, ex.getMessage());
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Throw exception if Adv is not installed
    */
    @isTest
    public static void moveOppsToContactAccountThrowException() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        ADV_Adapter theAdapter = new ADV_Adapter();
        Test.startTest();
        try {
            theAdapter.moveOppsToContactAccount(null, null);
            //Add this to make sure it throws exception
            System.assert(false);
        } catch (Exception ex) {
            System.assertEquals(Label.adapterException, ex.getMessage());
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Throw exception if Adv is not installed
    */
    @isTest
    public static void configAccountForContactThrowException() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        ADV_Adapter theAdapter = new ADV_Adapter();
        Test.startTest();
        try {
            theAdapter.configAccountForContact(null);
            //Add this to make sure it throws exception
            System.assert(false);
        } catch (Exception ex) {
            System.assertEquals(Label.adapterException, ex.getMessage());
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Throw exception if Adv is not installed
    */
    @isTest
    public static void configAccountTDTMThrowException() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        ADV_Adapter theAdapter = new ADV_Adapter();
        Test.startTest();
        try {
            theAdapter.configAccountTDTM(null, null, null);
            //Add this to make sure it throws exception
            System.assert(false);
        } catch (Exception ex) {
            System.assertEquals(Label.adapterException, ex.getMessage());
        }
        Test.stopTest();
    }
}