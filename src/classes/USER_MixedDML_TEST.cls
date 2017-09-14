@isTest
public with sharing class USER_MixedDML_TEST {
	@isTest
    public static void testInsertingUserWithTriggerHandlerMixedDML() {
        List<User> newUsers = USER_UserService_TEST.createUsers();
	}
}