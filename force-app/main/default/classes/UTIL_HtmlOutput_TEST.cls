/*
    Copyright (c) 2018 Salesforce.org
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
* @group Utilities
* @description Unit tests for UTIL_HtmlOutput class
*/
@isTest(IsParallel=true)
public with sharing class UTIL_HtmlOutput_TEST {
    /*******************************************************************************************************
    * @description Verifies a string with allowed tag with extra space is returned without escaping
    */
    @isTest
    private static void shouldReturnOriginalTagWithSpace() {
        String html = '<b> Bold is allowed </ b>';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = false;

        System.assertEquals(html, controller.getSafeHtml());
    }

    /*******************************************************************************************************
    * @description Verifies a string with allowed tag is returned without escaping
    */
    @isTest
    private static void shouldReturnOriginalTag() {
        String html = '<b> Bold is allowed </b>';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = false;

        System.assertEquals(html, controller.getSafeHtml());
    }

    /*******************************************************************************************************
    * @description Verifies a string with a tag that is not allowed is returned escaped
    */
    @isTest
    private static void shouldReturnEscapedTag() {
        String html = '<img src=x onerror=alert(document.domain)>';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = false;
        String actualHtml = controller.getSafeHtml();

        System.assert(actualHtml.startsWith('&lt;'));
        System.assertNotEquals(html, actualHtml);
    }

    /*******************************************************************************************************
    * @description Verifies a string with allowed url is returned without escaping
    */
    @isTest
    private static void shouldReturnOriginalUrl() {
        String html = '<a href="https://trailhead.salesforce.com/trailblazer-community/groups/0F94S000000kHitSAE">';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = true;

        System.assertEquals(html, controller.getSafeHtml());
    }

    /*******************************************************************************************************
    * @description Verifies a string with allowed url with extra space is returned without escaping
    */
    @isTest
    private static void shouldReturnOriginalUrlWithSpace() {
        String html = '<a href="https://trailhead.salesforce.com/trailblazer-community/groups/0F94S000000kHitSAE" >';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = true;

        System.assertEquals(html, controller.getSafeHtml());
    }

    /*******************************************************************************************************
    * @description Verifies a string with a url that is not allowed is returned escaped
    */
    @isTest
    private static void shouldReturnEscapedUrl() {
        String html = '<a href="www.google.com">';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = true;
        String actualHtml = controller.getSafeHtml();

        System.assert(actualHtml.startsWith('&lt;'));
        System.assertNotEquals(html, actualHtml);
    }

    /*******************************************************************************************************
    * @description Verifies that non-allowed javascript event code is stripped from url
    */
    @isTest
    private static void shouldStripJavaScriptFromUrl() {
        String html = '<a href="https://trailhead.salesforce.com/trailblazer-community/groups/0F94S000000kHitSAE" onanyjavascriptevent="alert(\'gotcha\')">';
        String cleanHtml = '<a href="https://trailhead.salesforce.com/trailblazer-community/groups/0F94S000000kHitSAE" >';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = true;

        System.assertEquals(cleanHtml, controller.getSafeHtml());
    }

    /*******************************************************************************************************
    * @description Verifies that non-allowed javascript event code is stripped from url, regardless of
    * the text case of the javascript
    */
    @isTest
    private static void shouldStripJavaScriptFromUrlRegardlessOfCase() {
        String html =
            '<a href="https://trailhead.salesforce.com/trailblazer-community/groups/0F94S000000kHitSAE" oNanyjavascriptevent="alert(\'gotcha\')">';
        String cleanHtml = '<a href="https://trailhead.salesforce.com/trailblazer-community/groups/0F94S000000kHitSAE" >';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = true;

        System.assertEquals(cleanHtml, controller.getSafeHtml());
    }

}
