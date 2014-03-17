@isTest
public with sharing class ADDR_Validation_Gateway_TEST {

    public static testMethod void testOneAddress() {
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        Test.StartTest();
        ADDR_Validation_Gateway la = new ADDR_Validation_Gateway('key', 'key');
        ADDR_Validation_Gateway.Response sr = la.verifyAddress( 'One Infinite Loop Cupertino, CA' );

        system.assert(sr != null);
        system.assertEquals(sr.delivery_line_1, '1 Infinite Loop');
        system.assertEquals(37.33118, sr.metadata.latitude);
        system.debug(logginglevel.warn, sr.getFullAddress());
    }

    public static testMethod void testMultiAddress() {
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        Test.StartTest();
        ADDR_Validation_Gateway la = new ADDR_Validation_Gateway('key');
        list<ADDR_Validation_Gateway.Response> srs = la.verifyAddresses( new list<String>{'One Infinite Loop Cupertino, CA', 'Two Infinite Loop Cupertino, CA'} );

        system.assert(srs != null && srs.size() == 2);
        system.assertEquals('1 Infinite Loop', srs[0].delivery_line_1);
        system.assertEquals(37.33118, srs[0].metadata.latitude);
        system.assertEquals('2 Infinite Loop', srs[1].delivery_line_1);
    }

    public static testMethod void testZip() {
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        Test.StartTest();
        ADDR_Zipcode_Validation_Gateway la = new ADDR_Zipcode_Validation_Gateway('key', 'key');
        ADDR_Zipcode_Validation_Gateway.Response sz = la.verifyZip( '98236' );

        system.assert(sz != null);
        system.assertEquals(3, sz.city_states.size());
        system.assertEquals(1, sz.zipcodes.size());
        system.assertEquals(47.957763, sz.zipcodes[0].latitude);

        sz = la.verifyZip( 'Clinton', 'WA' );
    }

    public static testMethod void testBadAuth() {
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        Test.StartTest();
        ADDR_Validation_Gateway.Response sr;
        try {
            ADDR_Validation_Gateway la = new ADDR_Validation_Gateway('bad-authentication-for-test');
            sr = la.verifyAddress( 'One Infinite Loop Cupertino, CA' );
        } catch (Exception e) {
            system.assertEquals('Not authenticated.', e.getMessage());
        }
        system.assertEquals(null, sr);
    }
}