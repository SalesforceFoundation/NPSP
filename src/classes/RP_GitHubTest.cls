/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
* @group Getting Started
* @description Component that coverage github functionality
*/

@isTest
public with sharing class RP_GitHubTest {

    /*********************************************************************************************************
    * @description operation
    *        load GitHub latest release from last stable version enable from Salesforce.org api (Github)
    * verify:
    *       GitHubWrapper object is uploaded
    */
    @isTest
    public static void testLoadReleaseNotesFromSFORG() {

        Boolean failedRequest = false;

        Test.setMock(HttpCalloutMock.class, new RP_GitHubTestMock(failedRequest));

        RP_GitHubController controller = new RP_GitHubController();

        Test.startTest();

        controller.loadLatestReleaseNotes();

        Test.stopTest();

        // Asserting that the controller isn't null
        System.assertNotEquals(controller, null);

        // Asserting that the wrapper object isn't returning null
        System.assertNotEquals(controller.gitHubData, null);

        // Asserting that each property isn't returning null
        System.assertNotEquals(controller.gitHubData.latestDate, null);
        System.assertNotEquals(controller.gitHubData.latestDownloadUrl, null);
        System.assertNotEquals(controller.gitHubData.latestVersion, null);
        System.assertNotEquals(controller.gitHubData.latestReleaseNotes, null);
        System.assertNotEquals(controller.gitHubData.latestProductName, null);

    }

    /*********************************************************************************************************
    * @description operation
    *        test failed request from salesforce.org Api (Github)
    * verify:
    *       GitHubWrapper object isn't uploaded
    */
    @isTest
    public static void testFailedRequest() {

        Boolean failedRequest = true;

        Test.setMock(HttpCalloutMock.class, new RP_GitHubTestMock(failedRequest));

        RP_GitHubController controller = new RP_GitHubController();

        Test.startTest();

        controller.loadLatestReleaseNotes();

        Test.stopTest();

        // Asserting that the controller isn't null
        System.assertNotEquals(controller, null);

        // Asserting that the wrapper object is returning null
        System.assertEquals(controller.gitHubData, null);

    }

    /*********************************************************************************************************
    * @description operation
    *        apply format to a String date and returns a new date with new format
    * verify:
    *       the date is formated correctly
    */
    @isTest
    public static void testFormatDate() {

        User user = UTIL_UnitTestData_TEST.createNewUserForTests(Datetime.now().getTime() + 'gettingstarteduser@salesforce.org.test');

        Map<String, Object> responseBodyMap = new Map<String, Object>();

        RP_GitHubController.GitHubWrapper wrapper = new RP_GitHubController.GitHubWrapper(responseBodyMap);

        Test.startTest();

        String newDate = null;

        System.runAs(user) {

            newDate = wrapper.formatDate('2017-07-17T17:50:03Z');
        }

        Test.stopTest();

        // Asserting that the new format date is returning the same date with another format
        System.assertEquals(newDate, '7/17/2017 5:50 pm');

    }

}