@IsTest
private class NPSP_Address_TEST {
    //Todo: test copyFromSObject
    @IsTest
    static void testBehavior() {
        NPSP_Address npspAddress = new NPSP_Address(
                new Contact(LastName='Test')
        );
    }
}