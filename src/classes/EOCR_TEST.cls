@IsTest
private class EOCR_TEST {

    @IsTest
    private static void getAccessTokenTest() {
        String accessToken = EOCR_Utilities.getAccessToken();
        System.debug('Access Token = ' + accessToken);

        System.assert(!String.isBlank(accessToken));
    }
}
