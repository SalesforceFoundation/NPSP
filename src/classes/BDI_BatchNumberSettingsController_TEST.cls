/*
    Copyright (c) 2020 Salesforce.org
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
@IsTest
public class BDI_BatchNumberSettingsController_TEST {

    @IsTest
    static void shouldActivate() {
        Id autoNumberId =
                AN_AutoNumberService_TEST_Helper.setupAutoNumber(false,
                        'abc-{000}', 0, false);
        System.assertEquals(false,
                AN_AutoNumberService_TEST_Helper.getAutoNumberById(autoNumberId).IsActive__c);
        BDI_BatchNumberSettingsController.activate(autoNumberId);

        System.assertEquals(true,
                AN_AutoNumberService_TEST_Helper.getAutoNumberById(autoNumberId).IsActive__c,
                'The AutoNumber record should be active.');
    }

    @IsTest
    static void shouldDeactivate() {
        Id autoNumberId =
                AN_AutoNumberService_TEST_Helper.setupAutoNumber(true,
                        'abc-{000}', 0, false);
        System.assertEquals(true,
                AN_AutoNumberService_TEST_Helper.getAutoNumberById(autoNumberId).IsActive__c);
        BDI_BatchNumberSettingsController.deactivate(autoNumberId);

        System.assertEquals(false,
                AN_AutoNumberService_TEST_Helper.getAutoNumberById(autoNumberId).IsActive__c,
                'The AutoNumber record should be inactive.');
    }

    @IsTest
    static void shouldSave() {
        BDI_BatchNumberSettingsController.save(AN_AutoNumberService_TEST_Helper.autoNumberJSON);
        System.assert(![SELECT Id FROM AutoNumber__c].isEmpty(),
                'The Auto Number should have been created.');
    }

    @IsTest
    static void shouldPreventSaveOfDuplicate() {
        BDI_BatchNumberSettingsController.save(AN_AutoNumberService_TEST_Helper.autoNumberJSON);
        try {
            BDI_BatchNumberSettingsController.save(AN_AutoNumberService_TEST_Helper.autoNumberJSON);
        } catch (AuraHandledException ahe) {
            System.assertNotEquals(null, ahe,
                    'An AuraHandledException should be thrown when attempting to insert a ' +
                            'duplicate Auto Number record.');
        }
    }

    @IsTest
    static void shouldGetAutoNumbers() {
        BDI_BatchNumberSettingsController.save(AN_AutoNumberService_TEST_Helper.autoNumberJSON);
        System.assert(!BDI_BatchNumberSettingsController.getAutoNumbers().isEmpty(),
                'The created Auto Number record should be returned.');
    }

}