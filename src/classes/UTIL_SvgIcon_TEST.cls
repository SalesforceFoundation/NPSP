/*
    Copyright (c) 2016, Salesforce.org
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
 * @group Utilities
 * @description Test Class that tests the utility that converts the static resource sprites to inline svg
 */
@isTest
private class UTIL_SvgIcon_TEST {

    @isTest
    private static void testGetIconMarkupForAddContact() {
        String expectedMarkup = '<svg aria-hidden="true" class="slds-icon slds-icon--large slds-icon-action-add-contact " name="add-contact" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><path d="M21.2 4.2H2.8C1.5 4.2.5 5.2.5 6.5v11c0 1.3 1 2.3 2.3 2.3h18.4c1.3 0 2.3-1 2.3-2.3v-11c0-1.3-1-2.3-2.3-2.3zm-9.8 13H4.8c-.7 0-1.3-.8-1.3-1.6.1-1.2 1.3-1.8 2.5-2.4.9-.4 1-.7 1-1.1 0-.4-.2-.7-.5-1-.5-.5-.8-1.2-.8-1.9 0-1.5.9-2.7 2.4-2.7s2.4 1.3 2.4 2.7c0 .8-.3 1.5-.8 1.9-.3.3-.6.6-.6 1s.1.7 1.1 1.1c1.2.5 2.4 1.2 2.4 2.4.2.8-.4 1.6-1.2 1.6zm9-2.7c0 .4-.3.8-.7.8h-3.5c-.4 0-.8-.3-.8-.8v-1.2c0-.4.4-.7.8-.7h3.5c.4 0 .7.3.7.7v1.2zm0-4.2c0 .4-.3.8-.7.8h-5.8c-.4 0-.7-.3-.7-.8V9.1c0-.4.3-.7.7-.7h5.8c.4 0 .8.3.8.7v1.2z" /></svg>';
        String spriteName = 'mockSprite';
        String symbolId = 'add_contact';
        String category = 'action';
        String iconName = 'add-contact';
        String size = 'large';
        String className = '';
        String prefix = 'slds-';

        String actualMarkup = UTIL_SvgIcon.getSvgIconMarkupAura(
            spriteName,
            symbolId,
            iconName,
            className,
            category,
            size,
            prefix
        );

        System.assertEquals(expectedMarkup, actualMarkup);
    }

    @isTest
    private static void testGetIconMarkupForInvalidId() {
        String spriteName = 'mockSprite';
        String symbolId = 'minus-contact';
        String category = 'action';
        String iconName = 'minus-contact';
        String size = 'large';
        String className = '';
        String prefix = 'slds-';

        try {
          String actualMarkup = UTIL_SvgIcon.getSvgIconMarkupAura(
            spriteName,
            symbolId,
            iconName,
            className,
            category,
            size,
            prefix
          );
          System.assert(false, 'A custom exception should be thrown');
        } catch (AuraHandledException e) {
          System.assert(e.getMessage().contains(symbolId), 'The symbol id is invalid and should not be found.');
        }
    }

    @isTest
    private static void testGetIconMarkupForInvalidName() {
        String spriteName = 'iDontExistSprite';
        String symbolId = 'add-contact';
        String category = 'action';
        String iconName = 'add-contact';
        String size = 'large';
        String className = '';
        String prefix = 'slds-';

        try {
          String actualMarkup = UTIL_SvgIcon.getSvgIconMarkupAura(
            spriteName,
            symbolId,
            iconName,
            className,
            category,
            size,
            prefix
          );
          System.assert(false, 'A custom exception should be thrown');
        } catch (Exception e) {
          System.assert(e.getMessage().contains(spriteName), 'The resource name is invalid and should not be found.');
        }
    }

}