/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group HGE
* @description Tests for the JWT creation utility.
*/

@IsTest
private class UTIL_Jwt_TEST {
// helper maps
    final static Map<String,String> encodeMap = new Map<String,String>{'MQ=='=>'MQ',
    'MTI='=>'MTI',
    'MTIz'=>'MTIz',
    'V2hlcmU/'=>'V2hlcmU_',
    'MjI+MQ=='=>'MjI-MQ'};

    final static Map<String,String> decodeMap = new Map<String,String>{'MQ'=>'MQ==',
    'MTI'=>'MTI=',
    'MTIz'=>'MTIz',
    'V2hlcmU_'=>'V2hlcmU/',
    'MjI-MQ'=>'MjI+MQ=='};

    @IsTest static void verifyTranscodeBase64ToBase64Url() {

        for (String key: encodeMap.keySet()) {
            System.assertEquals( encodeMap.get(key),
                    UTIL_Jwt.transcodeBase64ToBase64Url(key));
        }

        System.assertEquals( null, UTIL_Jwt.transcodeBase64ToBase64Url(null));
        System.assertEquals( '', UTIL_Jwt.transcodeBase64ToBase64Url(''));
        try {
            UTIL_Jwt.transcodeBase64ToBase64Url('MQ');
            System.assert(false, System.Label.geUtilJWTTestInvalidString);
        } catch(Exception e) {
            System.assertEquals(e.getMessage(), UTIL_Jwt.INVALID_BASE64_MESSAGE);
        }

    }

    @IsTest static void verifyTranscodeBase64UrlToBase64() {

        for (String key: decodeMap.keySet()) {
            System.assertEquals( decodeMap.get(key),
                    UTIL_Jwt.transcodeBase64UrlToBase64(key));
        }

        System.assertEquals( null, UTIL_Jwt.transcodeBase64UrlToBase64(null));
        System.assertEquals( '', UTIL_Jwt.transcodeBase64UrlToBase64(''));
        try {
            UTIL_Jwt.transcodeBase64UrlToBase64('MQ==');
            System.assert(false, System.Label.geUtilJWTTestInvalidString);
        } catch(Exception e) {
            System.assertEquals(e.getMessage(), UTIL_Jwt.INVALID_BASE64URL_MESSAGE);
        }

    }

    @IsTest static void verifyBase64String() {

        for (String key: encodeMap.keySet()) {
            System.assertEquals( true,
                    UTIL_Jwt.isBase64String(key));
        }

        for (String key: decodeMap.keySet()) {
            // this key has valid format for both base64 and base64url
            if (key!='MTIz') {
                System.assertEquals( false,
                        UTIL_Jwt.isBase64String(key));
            }
        }

    }

    @IsTest static void verifyBase64UrlString() {

        for (String key: decodeMap.keySet()) {
            System.assertEquals( true,
                    UTIL_Jwt.isBase64UrlString(key));
        }

        for (String key: encodeMap.keySet()) {
            // this key has valid format for both base64 and base64url
            if (key!='MTIz') {
                System.assertEquals( false,
                        UTIL_Jwt.isBase64UrlString(key));
            }
        }

    }

    @IsTest static void verifyGetSignedJWTFromString() {

        // test data 1
        String hardcodedResult = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJUaGUgQ0NTIFRlYW0i' +
                'fQ.ceCI-fP3o109cYjPEksS6uqWSS38FbHEmX1xD8BuVNM';
        String jwtPayload = '{"iss":"The CCS Team"}';
        String jwtKey = 'MTIzNA=='; // plain-text key: 1234

        // test data 2
        String hardcodedResult2 = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJqb2UiLCJleHAiOjEzMDA4MTkzODAsImh0d' +
                'HA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ.YK8MsSnWjPkqOUL0wIapSYQclpavl7mQpIG6J8rhbyQ';
        String jwtPayload2 = '{"iss":"joe","exp":1300819380,"http://example.com/is_root":true}';
        String jwtKey2 = 'TVE9PQ=='; // plain-text key: MQ==

        Test.startTest();
        // correct signatures
        System.assertEquals(hardcodedResult, UTIL_Jwt.getSignedJWTFromString(
                jwtPayload, jwtKey));
        System.assertEquals(hardcodedResult2, UTIL_Jwt.getSignedJWTFromString(
                jwtPayload2, jwtKey2));

        try {
            UTIL_Jwt.getSignedJWTFromString(jwtPayload, '');
            System.assert(false, System.Label.geUtilJWTTestInvalidKey);
        } catch(Exception e1) {
            System.assertEquals(e1.getMessage(), UTIL_Jwt.INVALID_KEY_MESSAGE);
        }

        try {
            UTIL_Jwt.getSignedJWTFromString(null, jwtKey);
            System.assert(false, System.Label.geUtilJWTTestInvalidPayload);
        } catch(Exception e2) {
            System.assertEquals(e2.getMessage(), UTIL_Jwt.INVALID_PAYLOAD_MESSAGE);
        }
        Test.stopTest();

    }

    @IsTest static void verifyGetSignedJWT() {

        // aux test data
        String issuer = 'The CCS Team';
        String key = 'MTIzNA==';
        Auth.JWT jwtInstance = new Auth.JWT();
        jwtInstance.setIss(issuer);

        System.assertNotEquals(null, UTIL_Jwt.getSignedJWT(jwtInstance, key));

        try {
            UTIL_Jwt.getSignedJWT(null, key);
            System.assert(false, System.Label.geUtilJWTTestInvalidPayload);
        } catch(Exception e) {
            System.assertEquals(e.getMessage(), UTIL_Jwt.INVALID_PAYLOAD_MESSAGE);
        }

        try {
            UTIL_Jwt.getSignedJWT(jwtInstance, null);
            System.assert(false, System.Label.geUtilJWTTestInvalidKey);
        } catch(Exception e2) {
            System.assertEquals(e2.getMessage(), UTIL_Jwt.INVALID_KEY_MESSAGE);
        }


    }
}