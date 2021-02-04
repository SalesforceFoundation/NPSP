/**
* @description Create a new standard user in the org using the "NPSP_Standard_User" profile created by the
* Create_Testing_User CCI Flow.
* @author Michael Smith
* @date 2020-03-09
*/
static final String TESTING_PROFILE = 'NPSP_Standard_User';
static final String lastname = 'User';
static final String firstname = 'NonSystemAdmin';

public static void createTestingUser() {
    Profile p = [SELECT Id FROM Profile WHERE Name = :TESTING_PROFILE LIMIT 1];

    String userAlias = lastName.replaceAll(' ', '').leftPad(8, '0').right(8);
    String userName = buildUniqueUsername();
    String userEmail = UserInfo.getUserEmail();

    if ([SELECT Count() FROM User WHERE UserName = :userName] == 1) {
        return;
    }

    User u = new User(
        LastName = lastName,
        FirstName = firstName,
        Email = userEmail,
        ProfileId = p.Id,
        Username = userName,
        Alias = userAlias,
        TimeZoneSidKey = UserInfo.getTimeZone().toString(),
        LocaleSidKey = UserInfo.getLocale(),
        LanguageLocaleKey = UserInfo.getLanguage(),
        EmailEncodingKey = 'ISO-8859-1'
    );

    insert u;
}

/**
 * @description Construct a unique last name to be assigned to a User
 * @return String
 */
private static String buildUniqueUsername() {
    return firstname + '.' + lastname + '@' + UserInfo.getOrganizationId() + '.scratch.org';
}

