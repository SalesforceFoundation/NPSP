/**
 * Created by lmeerkatz on 12/27/18.
 */

@isTest
private with sharing class BGE_BatchGiftEntry_UTIL_TEST {

    @isTest
    static void testTruncateList() {
        List<String> fruits = new List<String> { 'apple', 'banana', 'pear', 'orange' };
        System.assertEquals('apple, banana, pear, orange', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 5));
        System.assertEquals('apple, banana, pear, orange', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 4));
        System.assertEquals('apple, banana, pear ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 3));
        System.assertEquals('apple, banana ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 2));
        System.assertEquals('apple ...', BGE_BatchGiftEntry_UTIL.truncateList(fruits, 1));
    }

}