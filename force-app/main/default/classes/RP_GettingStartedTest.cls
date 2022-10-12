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
*
* @group Getting Started
*
* @description Component that coverage getting started functionality (links assing)
*/

@isTest
public with sharing class RP_GettingStartedTest {

    /*********************************************************************************************************
    * @description operation
    * load urls links into a new LinksWrapper object, this was created and load in the controller's constructor
    */
    @isTest
    public static void testGettingStartedLinks () {

        Test.startTest();

        RP_GettingStartedController controller = new RP_GettingStartedController();

        Test.stopTest();

        // Asserting that the page controller isn't null
        System.assertNotEquals(controller, null);

        // Asserting that the wrapper object isn't returning null
        System.assertNotEquals(controller.linksData, null);

        // Asserting that each property isn't returning null
        System.assertNotEquals(controller.linksData.trailheadLink, null);
        System.assertNotEquals(controller.linksData.usLink, null);
        System.assertNotEquals(controller.linksData.customerJourneyLink, null);
    }
}