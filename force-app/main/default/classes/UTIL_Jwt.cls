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
* @group Utilities
* @description Class which holds static methods for generating jwts
*/
public with sharing class UTIL_Jwt {
    // error messages consts
    @TestVisible private static final String INVALID_BASE64_MESSAGE = System.Label.geJWTUtilInvalidBase64Message;
    @TestVisible private static final String INVALID_BASE64URL_MESSAGE = System.Label.geJWTUtilInvalidBase64UrlMessage;
    @TestVisible private static final String INVALID_PAYLOAD_MESSAGE = System.Label.commonJWTInvalidPayload;
    @TestVisible private static final String INVALID_KEY_MESSAGE = System.Label.commonJWTInvalidKey;

    // private consts
    private static final String BASE64_REGEX = '^[a-zA-Z0-9\\+/]*={0,3}$';
    private static final String BASE64URL_REGEX = '^[a-zA-Z0-9_-]*$';
    private static final String ENC_ALG = 'HS256';
    private static final String ENC_TYPE = 'JWT';
    private static final String ALG_NAME = 'HmacSHA256';
    private static final Integer RIGHT_PAD_CONST = 4;

    // custom exception
    public class UTIL_JwtException extends Exception {}

    /**
     * @description Returns the compact serialization representation of the jwt as a concatenated string,
     *          with the encoded jwt header, encoded jwt payload, and encoded jwt signature strings
     *          separated by period ('.') characters
     * @param   Auth.JWT jwtInstance, instance
     * @param   String key, base64 encoded key
     * @return  String
     */
    public static String getSignedJWT(Auth.JWT jwtInstance, String key) {

        if (jwtInstance == null) {
            throw new UTIL_JwtException(INVALID_PAYLOAD_MESSAGE);
        }

        return getSignedJWTFromString(jwtInstance.toJSONString(), key);

    }

    /**
     * @description helper method to sign jwt using payload as string and base64 format key
     * @param   String payload, jwt payload ex: {"iss":"joe","exp":1300819380,"http://example.com/is_root":true}
     * @param   String key, base64 encoded key ex: TVE9PQ==
     * @return  String, returns the compact serialization representation of the jwt as a concatenated string,
     *          with the encoded jwt header, encoded jwt payload, and encoded jwt signature strings
     *          separated by period ('.') characters.
     */
    public static String getSignedJWTFromString(String payload, String key) {

        if (String.isBlank(payload)) {
            throw new UTIL_JwtException(INVALID_PAYLOAD_MESSAGE);
        }

        if (String.isBlank(key)) {
            throw new UTIL_JwtException(INVALID_KEY_MESSAGE);
        }

        String signatureInput = getJWTHeader() + '.' + encodeStringToBase64Url(payload);
        String encodedSecret = encodeStringToBase64Url(key);
        String signed = signatureInput + '.' + getJWTSignature( signatureInput, encodedSecret );
        return signed;

    }

    /**
     * @description encode string to base64Url format
     * @param   String input, string to encode into base64url
     * @return  String, base64url encoded string
     */
    private static String encodeStringToBase64Url(String input) {
        String base64Input = EncodingUtil.base64Encode(Blob.valueOf(input));
        return transcodeBase64ToBase64Url( base64Input );

    }

    /**
     * @description generates jwt header on base64Url format
     * @return  String, base64url jwt header
     */
    private static String getJWTHeader() {

        HeaderClass hClass = new HeaderClass( ENC_TYPE, ENC_ALG );
        String JWTHeader = encodeStringToBase64Url( JSON.serialize(hClass) );
        return JWTHeader;

    }

    /**
     * @description performs base64url encoded signature
     * @param   String signatureInput, combination of JWTHeader.JWTPayload on base64url format
     * @param   String key, base64 encoded key
     * @return  String, base64url encoded signature
     */
    private static String getJWTSignature(String signatureInput, String key) {

        // decode base64 key
        Blob decodedKey = EncodingUtil.base64Decode(key);
        Blob JWTSignature = Crypto.generateMac(ALG_NAME, Blob.valueOf(signatureInput), decodedKey);
        String jwtSignatureString = EncodingUtil.base64Encode(JWTSignature);
        // return base64url encoded signature
        return transcodeBase64ToBase64Url(jwtSignatureString);

    }

    /**
     * @description transcode Base64 into Base64url format
     * @param    String input, string to transcode
     * @return   String, to base64Url format
     */
    @TestVisible
    private static String transcodeBase64ToBase64Url(String input) {

        if (String.isBlank(input)) {
            return input;
        }

        if (!isBase64String(input)) {
            throw new UTIL_JwtException(INVALID_BASE64_MESSAGE);
        }

        return input.replace('/', '_').replace('+', '-').replaceAll('=+$', '');

    }

    /**
     * @description transcode Base64url into Base64 format
     * @param    String input, string to transcode
     * @return   String, to base64 format
     */
    @TestVisible
    private static String transcodeBase64UrlToBase64(String input) {

        if (String.isBlank(input)) {
            return input;
        }

        if (!isBase64UrlString(input)) {
            throw new UTIL_JwtException(INVALID_BASE64URL_MESSAGE);
        }

        Integer rightPad = input.length()< RIGHT_PAD_CONST ? RIGHT_PAD_CONST :
                Math.mod(input.length(), RIGHT_PAD_CONST) + input.length();
        return input.replace('-', '+')
                .replace('_', '/')
                .rightPad(rightPad)
                .replace(' ','=');

    }

    /**
     * @description return true if is valid base 64 string:
     *  String must be a multiple of 4, adding = until it is AND
     * 	the character set is [A-Z, a-z, 0-9, and + /]
     * @param    String input, string to validate
     * @return   Boolean, true if valid
     */
    @TestVisible
    private static Boolean isBase64String(String input) {

        Boolean multipleOf4 = Math.mod(input.length(), RIGHT_PAD_CONST) == 0;
        return multipleOf4 && regEx(input, BASE64_REGEX);

    }

    /**
     * @description return true if is valid base64url string:
     *  Character set is [A-Z, a-z, 0-9, and - _]
     * @param    String input, string to validate
     * @return   Boolean, true if valid
     */
    @TestVisible
    private static Boolean isBase64UrlString(String input) {
        return regEx(input, BASE64URL_REGEX);
    }

    /**
     * @description regex helper method
     * @param   String message, message to apply regular expression
     * @param 	String match, regex criteria
     * @return	Boolean, true if regular expression matches
     */
    private static Boolean regEx(String message, String match) {

        Pattern regexPattern = Pattern.compile(match);
        Matcher regexMatcher = regexPattern.matcher(message);
        return regexMatcher.find();

    }

    /**
     * @description inner-helper class to serialize jwt header
     */
    private class HeaderClass {

        // class att
        String typ;
        String alg;

        // constructor
        public HeaderClass(String type, String algorithm) {
            this.typ = type;
            this.alg = algorithm;
        }
    }
}