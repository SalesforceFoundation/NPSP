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
/**
* @author Salesforce.org
* @date 2022
* @group Utilities
* @description Tests specific to the UTIL_DuplicateMgmt class.
*/
@isTest
private with sharing class UTIL_DuplicateMgmt_TEST {

    /** 
    * @description Since we cannot create / change Duplicate Management rules via apex.  This test primarily
    * confirms that the batching of sObjects takes place so that it doesn't exceed the 50 record limit for findDuplicates
    */
    @isTest
    static void shouldProcessOver50SObjects() {
        UTIL_DuplicateMgmt dupeUtil = new UTIL_DuplicateMgmt();
        
        Sobject[] contSObjs = generateContactSobj(200);

        String exceptionMsg;
        Map<SObject,UTIL_DuplicateMgmt.MatchDetail[]> sObjToMatchResults;

        Test.startTest();

        try {
            sObjToMatchResults = dupeUtil.findDuplicatesBulk(contSObjs);
        } catch(Exception e) {
            exceptionMsg = e.getMessage();
        }

        Test.stopTest();

        // Skipping over the asserts if there is an exception message for now since an exception is thrown
        // in orgs that have no active contact duplicate rules.
        if (exceptionMsg == null) {
            System.assertEquals(200,sObjToMatchResults.size());

            Integer foundResult = 0;
            for (SObject contSObj : contSObjs) {
                if (sObjToMatchResults.containsKey(contSobj)) {
                    foundResult++;
                }
            }
    
            System.assertEquals(200, foundResult, 'SObject not included in results.');
        }
    }

    /** 
    * @description Tests the population of the return map with results.
    */
    @isTest
    static void shouldPopulateMatchDetails () {
        Map<SObject,UTIL_DuplicateMgmt.MatchDetail[]> sObjToMatchResults = 
            new Map<SObject,UTIL_DuplicateMgmt.MatchDetail[]>();
        Sobject[] contSObjs = generateContactSobj(5);

        for (Integer i = 0; i < contSObjs.size(); i ++) {
            Datacloud.DuplicateResult dupeResult;
            Datacloud.MatchResult matchResult;
            Datacloud.MatchRecord matchRecord;
            
            // Test storing result
            UTIL_DuplicateMgmt.storeMatchDetail(sObjToMatchResults,contSObjs[i],dupeResult,matchResult,matchRecord);

            // Store two match detail results for the first element
            if (i == 0) {
                UTIL_DuplicateMgmt.storeMatchDetail(
                    sObjToMatchResults,contSObjs[i],dupeResult,matchResult,matchRecord);
            } 
        }
        
        // Confirm there are the correct number of keys in the results
        System.assertEquals(5,sObjToMatchResults.size());

        UTIL_DuplicateMgmt.MatchDetail[] matchDetailsForFirst = sObjToMatchResults.get(contSobjs[0]);
        // Confirm that the first element has two match details
        System.assertEquals(2, matchDetailsForFirst.size());
    }

    /** 
    * @description Utility Method to create contact SObj
    */
    private static Sobject[] generateContactSobj (Integer numOfContacts) {
        SObject[] contSObjs = new Sobject[]{};
        for (Integer i = 0; i < numOfContacts; i ++) {
            Contact c = new Contact(FirstName = 'First' + i,
                                    LastName = 'Last' + i,
                                    Email = 'email' + i + '@fake.com');
            contSobjs.add((SObject)c);
        }
        return contSObjs;
    }
}
