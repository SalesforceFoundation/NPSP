/**
* @author Salesforce.org
* @date 2020
* @group GE
* @group-content
* @description test class for Einstein OCR methods
*/

@IsTest
private class EOCR_TEST {

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
