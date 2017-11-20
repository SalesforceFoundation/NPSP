/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Address Management
* @description test class that provides address validation/normalization services
* through the Cicero API.
 */

@isTest
public with sharing class ADDR_Cicero_TEST {
	
    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    /*********************************************************************************************************
    * @description a fake http response from Cicero for test code
    */
    private static string strResponseTest = 
'{'+
'  "response" : {'+
'    "results" : {'+
'      "candidates" : [ {'+
'        "geoservice" : "Google",'+
'        "match_subregion" : "San Francisco County",'+
'        "x" : -122.3948366,'+
'        "y" : 37.7938462,'+
'        "match_addr" : "1 Market St #300, San Francisco, CA 94105, USA",'+
'        "match_city" : "San Francisco",'+
'        "match_region" : "CA",'+
'        "score" : 0,'+
'        "locator" : "rooftop",'+
'        "districts" : [ {'+
'          "ocd_id" : "ocd-division/country:us/state:ca",'+
'          "data" : { },'+
'          "id" : 5,'+
'          "last_update_date" : "2012-03-18 07:46:32",'+
'          "num_officials" : 2,'+
'          "state" : "CA",'+
'          "subtype" : "UPPER",'+
'          "sk" : 5,'+
'          "label" : "California",'+
'          "valid_to" : null,'+
'          "district_id" : "CA",'+
'          "country" : "US",'+
'          "valid_from" : "1977-05-18 00:00:00",'+
'          "city" : "",'+
'          "district_type" : "NATIONAL_UPPER"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us",'+
'          "data" : { },'+
'          "id" : 19,'+
'          "last_update_date" : "2012-03-18 07:46:32",'+
'          "num_officials" : 2,'+
'          "state" : "",'+
'          "subtype" : "NATION",'+
'          "sk" : 19,'+
'          "label" : "United States",'+
'          "valid_to" : null,'+
'          "district_id" : "UNITED STATES",'+
'          "country" : "US",'+
'          "valid_from" : "0001-01-01 04:56:02",'+
'          "city" : "",'+
'          "district_type" : "NATIONAL_EXEC"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca",'+
'          "data" : { },'+
'          "id" : 87,'+
'          "last_update_date" : "2012-03-18 07:46:32",'+
'          "num_officials" : 2,'+
'          "state" : "CA",'+
'          "subtype" : "STATE",'+
'          "sk" : 87,'+
'          "label" : "California",'+
'          "valid_to" : null,'+
'          "district_id" : "CA",'+
'          "country" : "US",'+
'          "valid_from" : "0001-01-01 04:56:02",'+
'          "city" : "",'+
'          "district_type" : "STATE_EXEC"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca/place:san_francisco",'+
'          "data" : { },'+
'          "id" : 279,'+
'          "last_update_date" : "2012-03-18 07:46:32",'+
'          "num_officials" : 1,'+
'          "state" : "CA",'+
'          "subtype" : "CITY",'+
'          "sk" : 279,'+
'          "label" : "San Francisco city",'+
'          "valid_to" : "9999-12-31 00:00:00",'+
'          "district_id" : "SAN FRANCISCO",'+
'          "country" : "US",'+
'          "valid_from" : "0001-01-01 04:56:02",'+
'          "city" : "San Francisco",'+
'          "district_type" : "LOCAL_EXEC"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca/county:san_francisco/council_district:6",'+
'          "data" : { },'+
'          "id" : 1691,'+
'          "last_update_date" : "2012-03-18 07:46:31",'+
'          "num_officials" : 1,'+
'          "state" : "CA",'+
'          "subtype" : "COUNTY",'+
'          "sk" : 1691,'+
'          "label" : "San Francisco City Council district 6",'+
'          "valid_to" : "9999-12-31 00:00:00",'+
'          "district_id" : "6",'+
'          "country" : "US",'+
'          "valid_from" : "0001-01-01 04:56:02",'+
'          "city" : "San Francisco",'+
'          "district_type" : "LOCAL"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca/county:san francisco",'+
'          "data" : { },'+
'          "id" : 2253,'+
'          "last_update_date" : "2012-03-18 07:46:31",'+
'          "num_officials" : 0,'+
'          "state" : "CA",'+
'          "subtype" : "COUNTY",'+
'          "sk" : 2253,'+
'          "label" : "San Francisco city",'+
'          "valid_to" : null,'+
'          "district_id" : "AT LARGE",'+
'          "country" : "US",'+
'          "valid_from" : "0001-01-01 04:56:02",'+
'          "city" : "San Francisco",'+
'          "district_type" : "LOCAL"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca11",'+
'          "data" : { },'+
'          "id" : 383744,'+
'          "last_update_date" : "2012-03-23 15:06:30",'+
'          "num_officials" : 0,'+
'          "state" : "CA",'+
'          "subtype" : "UPPER",'+
'          "sk" : 383744,'+
'          "label" : "",'+
'          "valid_to" : null,'+
'          "district_id" : "11",'+
'          "country" : "US",'+
'          "valid_from" : "2012-03-26 21:14:08.201488",'+
'          "city" : "",'+
'          "district_type" : "STATE_UPPER_REDISTRICTED"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca17",'+
'          "data" : { },'+
'          "id" : 385724,'+
'          "last_update_date" : "2012-03-22 15:22:42",'+
'          "num_officials" : 0,'+
'          "state" : "CA",'+
'          "subtype" : "LOWER",'+
'          "sk" : 385724,'+
'          "label" : "",'+
'          "valid_to" : null,'+
'          "district_id" : "17",'+
'          "country" : "US",'+
'          "valid_from" : "2012-03-26 21:18:41.419987",'+
'          "city" : "",'+
'          "district_type" : "STATE_LOWER_REDISTRICTED"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca12",'+
'          "data" : { },'+
'          "id" : 388478,'+
'          "last_update_date" : "2012-03-26 21:44:46",'+
'          "num_officials" : 0,'+
'          "state" : "CA",'+
'          "subtype" : "LOWER",'+
'          "sk" : 388478,'+
'          "label" : "",'+
'          "valid_to" : null,'+
'          "district_id" : "12",'+
'          "country" : "US",'+
'          "valid_from" : "2012-03-26 21:56:48.256155",'+
'          "city" : "",'+
'          "district_type" : "NATIONAL_LOWER_REDISTRICTED"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca6",'+
'          "data" : { },'+
'          "id" : 393743,'+
'          "last_update_date" : "2012-05-09 00:00:00",'+
'          "num_officials" : 0,'+
'          "state" : "CA",'+
'          "subtype" : "CITY",'+
'          "sk" : 393743,'+
'          "label" : "",'+
'          "valid_to" : null,'+
'          "district_id" : "6",'+
'          "country" : "US",'+
'          "valid_from" : "2012-05-09 00:00:00",'+
'          "city" : "SAN FRANCISCO",'+
'          "district_type" : "LOCAL_REDISTRICTED"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca/sldl:17",'+
'          "data" : { },'+
'          "id" : 752693,'+
'          "last_update_date" : "2012-11-12 00:00:00",'+
'          "num_officials" : 1,'+
'          "state" : "CA",'+
'          "subtype" : "LOWER",'+
'          "sk" : 752693,'+
'          "label" : "California Assembly district 17",'+
'          "valid_to" : "2022-12-05 00:00:00",'+
'          "district_id" : "17",'+
'          "country" : "US",'+
'          "valid_from" : "2012-12-03 00:00:00",'+
'          "city" : "",'+
'          "district_type" : "STATE_LOWER"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca/sldu:11",'+
'          "data" : { },'+
'          "id" : 752749,'+
'          "last_update_date" : "2012-11-12 00:00:00",'+
'          "num_officials" : 1,'+
'          "state" : "CA",'+
'          "subtype" : "UPPER",'+
'          "sk" : 752749,'+
'          "label" : "California State Senate district 11",'+
'          "valid_to" : "2022-12-05 00:00:00",'+
'          "district_id" : "11",'+
'          "country" : "US",'+
'          "valid_from" : "2012-12-03 00:00:00",'+
'          "city" : "",'+
'          "district_type" : "STATE_UPPER"'+
'        }, {'+
'          "ocd_id" : "ocd-division/country:us/state:ca/cd:12",'+
'          "data" : { },'+
'          "id" : 757216,'+
'          "last_update_date" : "2012-11-30 00:00:00",'+
'          "num_officials" : 1,'+
'          "state" : "CA",'+
'          "subtype" : "LOWER",'+
'          "sk" : 757216,'+
'          "label" : "California\'s 12th congressional district",'+
'          "valid_to" : "2023-01-03 00:00:00",'+
'          "district_id" : "12",'+
'          "country" : "US",'+
'          "valid_from" : "2013-01-03 00:00:00",'+
'          "city" : "",'+
'          "district_type" : "NATIONAL_LOWER"'+
'        } ],'+
'        "match_country" : "US",'+
'        "wkid" : 4326,'+
'        "match_postal" : "94105",'+
'        "count" : {'+
'          "from" : 0,'+
'          "total" : 13,'+
'          "to" : 12'+
'        }'+
'      } ]'+
'    },'+
'    "messages" : [ ],'+
'    "errors" : [ ]'+
'  }'+
'}';
    
    /*********************************************************************************************************
    * @description returns the HTTP Response from the HTTP Request for Cicero.
    * @param req the HTTP Request object
    * *returns HTTPResponse
    */
    public static HTTPResponse respond(HTTPRequest req) {        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(strResponseTest);
        res.setStatusCode(200);
        return res;
    }

    /*********************************************************************************************************
    * @description Tests validating a single address.
    */
	private static testmethod void singleValidAddr() {
        if (strTestOnly != '*' && strTestOnly != 'NewContactsNoAccounts') return;

        list<Address__c> listAddr = new list<Address__c>();
        Address__c addr = new Address__c();
        addr.MailingStreet__c = '1 market st #300';
        addr.MailingCity__c = 'san francisco';
        addr.MailingState__c = 'ca';
        addr.MailingPostalCode__c = '94105-1234';
        listAddr.add(addr);
        
        ADDR_Cicero_Validator cicero = new ADDR_Cicero_Validator();
        Addr_Verification_Settings__c settings = new Addr_Verification_Settings__c();
        settings.Auth_Token__c = 'foo';  // we need a fake token or we won't validate
        settings.Address_Verification_Endpoint__c = 'bar';
        List<Address__c> listAddrVerified = cicero.verifyRecords(listAddr, settings);
        system.assertEquals(1, listAddrVerified.size());
        //system.assertNotEquals(null, listAddrVerified[0].Pre_Verification_Address__c);
        system.assertEquals(true, listAddrVerified[0].Verified__c);
        system.assertEquals('1 Market St #300', listAddrVerified[0].MailingStreet__c);
        system.assertEquals('San Francisco', listAddrVerified[0].MailingCity__c);
        system.assertEquals('CA', listAddrVerified[0].MailingState__c);
        system.assertEquals('94105-1234', listAddrVerified[0].MailingPostalCode__c);
        system.assertEquals('17', listAddrVerified[0].State_Lower_District__c);
        system.assertEquals('11', listAddrVerified[0].State_Upper_District__c);

	}

    /*********************************************************************************************************
    * @description Tests that user can choose to not have the Cicero response overwrite their address.
    */
    private static testmethod void doesNotOverwriteAddr() {
        if (strTestOnly != '*' && strTestOnly != 'NewContactsNoAccounts') return;

        list<Address__c> listAddr = new list<Address__c>();
        Address__c addr = new Address__c();
        addr.MailingStreet__c = '';
        addr.MailingCity__c = 'san francisco';
        addr.MailingState__c = 'ca';
        addr.MailingPostalCode__c = '94105';
        listAddr.add(addr);

        ADDR_Cicero_Validator cicero = new ADDR_Cicero_Validator();
        Addr_Verification_Settings__c settings = new Addr_Verification_Settings__c();
        settings.Auth_Token__c = 'foo';  // we need a fake token or we won't validate
        settings.Address_Verification_Endpoint__c = 'bar';
        settings.Prevent_Address_Overwrite__c = true;
        List<Address__c> listAddrVerified = cicero.verifyRecords(listAddr, settings);

        system.assertEquals(1, listAddrVerified.size());
        system.assertEquals(true, listAddrVerified[0].Verified__c);
        system.assertEquals('', listAddrVerified[0].MailingStreet__c);
        system.assertEquals('san francisco', listAddrVerified[0].MailingCity__c);
        system.assertEquals('ca', listAddrVerified[0].MailingState__c);
        system.assertEquals('94105', listAddrVerified[0].MailingPostalCode__c);
        system.assertEquals('17', listAddrVerified[0].State_Lower_District__c);
        system.assertEquals('11', listAddrVerified[0].State_Upper_District__c);

    }
    /*********************************************************************************************************
    * @description Tests that user can allow Cicero response to overwrite the provided address.
    */
    private static testmethod void doesOverwriteAddr() {
        if (strTestOnly != '*' && strTestOnly != 'NewContactsNoAccounts') return;

        list<Address__c> listAddr = new list<Address__c>();
        Address__c addr = new Address__c();
        addr.MailingStreet__c = '1 market';
        addr.MailingCity__c = '';
        addr.MailingState__c = 'ca';
        addr.MailingPostalCode__c = '94105';
        listAddr.add(addr);

        ADDR_Cicero_Validator cicero = new ADDR_Cicero_Validator();
        Addr_Verification_Settings__c settings = new Addr_Verification_Settings__c();
        settings.Auth_Token__c = 'foo';  // we need a fake token or we won't validate
        settings.Address_Verification_Endpoint__c = 'bar';
        settings.Prevent_Address_Overwrite__c = false;
        List<Address__c> listAddrVerified = cicero.verifyRecords(listAddr, settings);

        system.assertEquals(1, listAddrVerified.size());
        system.assertEquals(true, listAddrVerified[0].Verified__c);
        system.assertEquals('1 Market St #300', listAddrVerified[0].MailingStreet__c);
        system.assertEquals('San Francisco', listAddrVerified[0].MailingCity__c);
        system.assertEquals('CA', listAddrVerified[0].MailingState__c);
        system.assertEquals('94105', listAddrVerified[0].MailingPostalCode__c);
        system.assertEquals('17', listAddrVerified[0].State_Lower_District__c);
        system.assertEquals('11', listAddrVerified[0].State_Upper_District__c);

    }
}