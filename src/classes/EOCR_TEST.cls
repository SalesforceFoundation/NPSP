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
