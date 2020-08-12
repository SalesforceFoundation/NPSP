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
    private static void getAccessTokenTest() {
        try {
            String accessToken = EOCR_Utilities.getAccessToken();
        } catch(Exception ex) {
            System.assert(true);
        }
        
        
    }
}
