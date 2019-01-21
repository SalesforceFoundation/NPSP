/**
 * Created by lmeerkatz on 12/27/18.
 */

@isTest
private with sharing class BGE_BatchGiftEntry_UTIL_TEST {

    /*********************************************************************************************************
    * @description Tests truncateList()
    */
    @isTest
    static void testTruncateList() {
        List<String> fruits = new List<String> { 'apple', 'banana', 'pear', 'orange' };
        System.assertEquals('apple, banana, pear, orange', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 5));
        System.assertEquals('apple, banana, pear, orange', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 4));
        System.assertEquals('apple, banana, pear ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 3));
        System.assertEquals('apple, banana ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 2));
        System.assertEquals('apple ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 1));
    }

    /*********************************************************************************************************
    * @description Tests handleMissingPermissions() methods
    */
    @isTest
    static void testHandleMissingPermissions() {
        List<DescribeFieldResult> dfrs = new List<DescribeFieldResult>();
        dfrs.add(UTIL_Describe.getFieldDescribe('Account','Name'));
        dfrs.add(UTIL_Describe.getFieldDescribe('Account','CreatedById'));
        String expectedErrorMsg = Label.bgeFLSError + ' [Account Name, Created By ID]';

        try {
            BGE_BatchGiftEntry_UTIL.handleMissingPermissions(dfrs);
        } catch (AuraHandledException ex) {
            System.assertEquals(expectedErrorMsg, ex.getMessage());
        }
    }

    /*********************************************************************************************************
    * @description Tests checkFieldPermissionsNeededForBatch() methods
    */
    @isTest
    static void testCheckFieldPermissionsNeededForBatch() {
        Boolean hasError = false;
        try {
            BGE_BatchGiftEntry_UTIL.checkFieldPermissionsNeededForBatch();
        } catch (AuraHandledException ex) {
            hasError = true;
            String errorMsg = ex.getMessage();
            System.assert(errorMsg.contains(Label.bgeFLSError), 'Only perms errors should be thrown.');
        } catch (Exception ex) {
            hasError = true;
            System.assert(false, 'Unhandled exception thrown.');
        }

        if (!hasError) {
            System.assert(true);
        }
    }

}