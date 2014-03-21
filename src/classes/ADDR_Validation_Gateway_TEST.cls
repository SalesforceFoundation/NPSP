/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Class that tests ADDR_SmartyStreets_Gateway class.
*/
@isTest
public with sharing class ADDR_Validation_Gateway_TEST {

    public static testMethod void testOneAddress() {
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        Test.StartTest();
        ADDR_SmartyStreets_Gateway la = new ADDR_SmartyStreets_Gateway('key', 'key');
        ADDR_SmartyStreets_Gateway.AddressResponse sr = la.verifyAddress( 'One Infinite Loop Cupertino, CA' );

        system.assert(sr != null);
        system.assertEquals(sr.delivery_line_1, '1 Infinite Loop');
        system.assertEquals(37.33118, sr.metadata.latitude);
        system.debug(logginglevel.warn, sr.getFullAddress());
    }

    public static testMethod void testMultiAddress() {
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        Test.StartTest();
        ADDR_SmartyStreets_Gateway la = new ADDR_SmartyStreets_Gateway('key');
        list<ADDR_SmartyStreets_Gateway.AddressResponse> srs = la.verifyAddresses( new list<String>{'One Infinite Loop Cupertino, CA', 'Two Infinite Loop Cupertino, CA'} );

        system.assert(srs != null && srs.size() == 2);
        system.assertEquals('1 Infinite Loop', srs[0].delivery_line_1);
        system.assertEquals(37.33118, srs[0].metadata.latitude);
        system.assertEquals('2 Infinite Loop', srs[1].delivery_line_1);
    }

    public static testMethod void testZip() {
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        Test.StartTest();
        ADDR_SmartyStreets_Gateway la = new ADDR_SmartyStreets_Gateway('key', 'key');
        ADDR_SmartyStreets_Gateway.ZipResponse sz = la.verifyZip( '98236' );

        system.assert(sz != null);
        system.assertEquals(3, sz.city_states.size());
        system.assertEquals(1, sz.zipcodes.size());
        system.assertEquals(47.957763, sz.zipcodes[0].latitude);

        sz = la.verifyZip( 'Clinton', 'WA' );
    }

    public static testMethod void testBadAuth() {
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        Test.StartTest();
        ADDR_SmartyStreets_Gateway.AddressResponse sr;
        try {
            ADDR_SmartyStreets_Gateway la = new ADDR_SmartyStreets_Gateway('bad-authentication-for-test');
            sr = la.verifyAddress( 'One Infinite Loop Cupertino, CA' );
        } catch (Exception e) {
            system.assertEquals('Not authenticated.', e.getMessage());
        }
        system.assertEquals(null, sr);
    }
}