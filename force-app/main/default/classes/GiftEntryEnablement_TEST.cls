/*
    Copyright (c) 2022, Salesforce.org
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
private class GiftEntryEnablement_TEST {

    @IsTest
    private static void enableShouldUpdateCustomSetting() {
        GiftEntryEnablementService giftEntryEnablementService = new GiftEntryEnablementService();
        AdvancedMappingEnablementServiceMock advancedMappingEnablementServiceMock = new
                AdvancedMappingEnablementServiceMock();
        advancedMappingEnablementServiceMock.setEnabled();

        giftEntryEnablementService.advancedMappingEnablementService = (AdvancedMappingEnablementService)Test.createStub(
                AdvancedMappingEnablementService.class, advancedMappingEnablementServiceMock);

        Test.startTest();
            giftEntryEnablementService.enable();
        Test.stopTest();

        System.assert(giftEntryEnablementService.isEnabled(), 'Gift entry should be enabled');
    }

    @IsTest
    private static void enableThrowsExceptionWhenMappingIsNotEnabled() {
        GiftEntryEnablementService giftEntryEnablementService = new GiftEntryEnablementService();
        AdvancedMappingEnablementServiceMock advancedMappingEnablementServiceMock = new
                AdvancedMappingEnablementServiceMock();

        giftEntryEnablementService.advancedMappingEnablementService = (AdvancedMappingEnablementService)Test.createStub(
                AdvancedMappingEnablementService.class, advancedMappingEnablementServiceMock);

        GiftEntryEnablementService.GiftEntryEnablementException enablementException;

        Test.startTest();
            try {
                giftEntryEnablementService.enable();
            } catch(GiftEntryEnablementService.GiftEntryEnablementException ex) {
                enablementException = ex;
            }
        Test.stopTest();

        System.assert(enablementException != null, 'An exception should be thrown when advanced mapping is not ' +
                'enabled.');
    }
}