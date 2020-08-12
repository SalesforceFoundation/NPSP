/**
* @author Salesforce.org
* @date 2020
* @group GE
* @group-content
* @description test class for Einstein OCR methods
*/

@IsTest
private class EOCR_TEST {
    private static final String EMAIL = 'developer@salesforce.com';
    private static final String PRIVATE_KEY = 'private_key_12344567890';
    private static final String ACCESS_TOKEN = 'aABbCcDdEeFf1234567890';
    private static final String FAILED_RESPONSE = '';

    @IsTest
    private static void getAccessTokenShouldFailWithoutConfiguration() {
        Test.startTest();
        try {
            EOCR_Utilities.getAccessToken();
            System.assert(false, 'Expected EinsteinAuthException');
        }
        catch (Exception e) {
            System.assert(e instanceof EOCR_Utilities.EinsteinAuthException);
            System.AssertEquals(e.getMessage().contains(EOCR_Utilities.MISSING_CONFIGURATION), true);
        }
        Test.stopTest();
    }

}
