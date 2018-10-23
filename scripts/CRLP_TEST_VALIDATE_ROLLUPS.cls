/**
 * Created by Michael Smith on 1/26/18.
 *
 * - CREATE TEST DATA AND AND TEST BOTH LEGACY AND CUSTOMIZABLE ROLLUP ENGINE BY VALIDATING THE
 *   RESULTING FIELD VALUES AGAINST EXPECTED RESULTS.
 * - REQUIRES 5 CUSTOM FIELDS ON THE ACCOUNT WITH CORRESPONDING ROLLUP CMT RECORDS
 *      1. TEST_Total_Payments__c
 *      2. TEST_Total_Writeoffs__c
 *      3. TEST_Soft_Credit_Total__c
 *      4. TEST_Acc_Soft_Credit_Total__c
 *      5. TEST_Acc_Soft_Credit_Largest_Amt__c
 * - REQUIRES CRLPs TO BE ENABLED IN TEST ORG
 * - CAN USE createCustomRollups METHOD BELOW FROM ANON APEX TO CREATE THE EXTRA CMT RECORDS
 * - SINCE THE DEFAULT IS TO INCLUDE MEMBERSHIP RECORD IN ALL ROLLUPS, THIS ASSUMES MEMBERSHIPS ARE INCLUDED
 * - ALL TESTS ARE CONDUCTED USING EXECUTE ANONYMOUS; EXECUTING ONE METHOD AT A TIME IN THE FOLLOWING ORDER:
 *   CRLP_TEST_VALIDATE_ROLLUPS.deleteTestData();
 *   CRLP_TEST_VALIDATE_ROLLUPS.createTestDataASync();
 *   CRLP_TEST_VALIDATE_ROLLUPS.executeLegacyRollups();
 *   CRLP_TEST_VALIDATE_ROLLUPS.validateRollups();
 *   CRLP_TEST_VALIDATE_ROLLUPS.executeCustomizableRollups();
 *   CRLP_TEST_VALIDATE_ROLLUPS.validateRollups();
 *   CRLP_TEST_VALIDATE_ROLLUPS.deleteTestData();
 */
public class CRLP_TEST_VALIDATE_ROLLUPS {

    // TODO -- Add support for verifying that dupe OCR's for Soft Credit Contact Roles are not duped in results

    private static Boolean ROLLUPS_INCLUDES_MEMBERSHIP = true;

    // When testing in a multicurrency org, set up CAD with this rate: 1.2311
    private static final Double CURR_EXCHANGE_RATE = 2.0;

    private static final String ACCOUNT_NAME_RD = 'CRLP TEST RD ACCOUNT 3';
    private static final String ACCOUNT_NAME_ORG = 'CRLP TEST ORG ACCOUNT 4';
    private static final String ACCOUNT_NAME_ASC = 'CRLP TEST ASC ACCOUNT';
    private static final String TEST_SITE_NAME = 'TEST_DATA';
    private static final String ORG_CONTACT_NAME = 'CRLPTEST-ORG-DONATION';
    private static final String GAU_NAME = 'CRLP Default GAU';
    private static final String RD_NAME = 'CRLP TEST RD';
    private static final String ACCOUNT_SOFT_CREDIT_ROLE_A = 'Influencer';
    private static final String ACCOUNT_SOFT_CREDIT_ROLE_B = 'Donation Source';

    private static final Decimal ORG_DONATION_AMT = 5000;
    private static final Decimal BASE_AMOUNT_USD = 100;
    private static final Decimal RD_AMOUNT_USD = 150;
    private static final Decimal OPPORTUNITY_AMOUNT = (UserInfo.isMultiCurrencyOrganization() ? BASE_AMOUNT_USD*CURR_EXCHANGE_RATE : BASE_AMOUNT_USD);
    private static final Decimal ACCOUNT_SOFT_CREDIT_BASE_AMOUNT = BASE_AMOUNT_USD/2;
    private static final Decimal ACCOUNT_SOFT_CREDIT_AMOUNT = (UserInfo.isMultiCurrencyOrganization() ? ACCOUNT_SOFT_CREDIT_BASE_AMOUNT*CURR_EXCHANGE_RATE : ACCOUNT_SOFT_CREDIT_BASE_AMOUNT);
    private static final Integer OPP_COUNT_PER_ACCT = 500;
    private static final Integer CLOSED_OPP_COUNT_PER_ACCT = 450;

    private static final Date MEMBERSHIP_FIRST_DATE = Date.newInstance(2015,6,30);
    private static final Decimal MEMBERSHIP_AMOUNT = 25;
    private static final Decimal MEMBERSHIP_TOTAL = (MEMBERSHIP_AMOUNT*4);
    private static final Integer MEMBERSHIP_COUNT = 4;

    private static final Decimal ROLLUP_TOTAL_WON_AMOUNT = (CLOSED_OPP_COUNT_PER_ACCT * BASE_AMOUNT_USD)
            + (ROLLUPS_INCLUDES_MEMBERSHIP ? MEMBERSHIP_TOTAL : 0);
    private static final Decimal ROLLUP_TOTAL_WON_COUNT = CLOSED_OPP_COUNT_PER_ACCT
            + (ROLLUPS_INCLUDES_MEMBERSHIP ? MEMBERSHIP_COUNT : 0);
    private static final Decimal ROLLUP_TOTAL_LASTYEAR = 15000 + MEMBERSHIP_AMOUNT ;
    private static final Decimal ROLLUP_AVERAGE = ROLLUP_TOTAL_WON_AMOUNT.divide(ROLLUP_TOTAL_WON_COUNT, 2, System.RoundingMode.HALF_UP);
    private static final Decimal ROLLUP_LARGEST = BASE_AMOUNT_USD;
    private static final Decimal ROLLUP_SMALLEST = (ROLLUPS_INCLUDES_MEMBERSHIP ? MEMBERSHIP_AMOUNT : BASE_AMOUNT_USD);
    private static final Date ROLLUP_FIRSTDATE = Date.newInstance(2015, 1, 2);
    private static final Date ROLLUP_LASTTDATE = (ROLLUPS_INCLUDES_MEMBERSHIP ?  Date.newInstance(2018, 6, 30) : Date.newInstance(2017,10,28));
    private static final String ROLLUP_BEST_YEAR = '2015';  // All 3 years have 150 donations, so 2015 is the first

    private static final Decimal ROLLUP_TOTAL_PAYMENT_AMOUNT = ROLLUP_TOTAL_WON_AMOUNT;
    private static final Decimal ROLLUP_TOTAL_WRITEOFF_AMOUNT = (OPP_COUNT_PER_ACCT-CLOSED_OPP_COUNT_PER_ACCT)*BASE_AMOUNT_USD;

    private static final Decimal ALLOC_TOTAL_AMOUNT = ROLLUP_TOTAL_WON_AMOUNT * 2;
    private static final Decimal ALLOC_TOTAL_COUNT = ROLLUP_TOTAL_WON_COUNT * 2;
    private static final Decimal ALLOC_AVERAGE = ALLOC_TOTAL_AMOUNT.divide(ALLOC_TOTAL_COUNT, 2);

    private static List<Account> accounts;
    private static List<Contact> contacts;
    private static List<Opportunity> opps;
    private static General_Accounting_Unit__c gau;

// ========================================================================================================
// PUBLIC METHODS
// ========================================================================================================

    /** *****************************************************************************************
    * @description Create the Test Data
    */
    public static void createTestDataASync() {
        // have to run this twice when multicurrency is enabled in the org
        if ([SELECT Count() FROM Account WHERE Site = :TEST_SITE_NAME LIMIT 1] == 0) {
            createAccountsAndContacts();
            createGAU();
            createOpportunitiesASync();
        }
    }

    /** *****************************************************************************************
    * @description Delete the Test Data
    */
    public static void deleteTestData() {
        // Disable non-User Managed TDTM triggers before the DML operation
        for (Trigger_Handler__c th : TDTM_Config_API.getCachedRecords()) {
            if (th.Object__c == 'Opportunity' || th.Object__c == 'Account' || th.Object__c == 'Contact' || th.Object__c == 'Allocation__c') {
                th.Active__c = false;
            }
        }

        Database.delete([SELECT Id FROM Allocation__c WHERE General_Accounting_Unit__r.Name = :GAU_NAME]);
        Database.delete([SELECT Id FROM Opportunity WHERE Account.Site = :TEST_SITE_NAME]);
        Database.delete([SELECT Id FROM Contact WHERE Account.Site = :TEST_SITE_NAME]);
        Database.delete([SELECT Id FROM Account WHERE Site = :TEST_SITE_NAME]);
        Database.delete([SELECT Id FROM General_Accounting_Unit__c WHERE Name = :GAU_NAME]);
        Database.delete([SELECT Id FROM npe03__Recurring_Donation__c WHERE Name = :RD_NAME LIMIT 1]);
    }

    /** *****************************************************************************************
    * @description Execute the Legacy Rollups for the Account and Contact objects
    */
    public static void executeLegacyRollups() {
        Customizable_Rollup_Settings__c cs = Customizable_Rollup_Settings__c.getOrgDefaults();
        cs.Customizable_Rollups_Enabled__c = false;
        update cs;

        clearTargetRecords();

        RLLP_OppRollup_UTIL rlpUtil = new RLLP_OppRollup_UTIL();
        String acctSOQL = rlpUtil.buildAccountQuery() + ' WHERE Site = :TEST_SITE_NAME';
        String contactSOQL = rlpUtil.buildContactQuery() + ' WHERE Account.Site = :TEST_SITE_NAME';
        Map<Id, Account> accountsMap = new Map<Id, Account>((List<Account>)Database.query(acctSOQL));
        Map<Id, Contact> contactsMap = new Map<Id, Contact>((List<Contact>)Database.query(contactSOQL));

        RLLP_OppRollup rlpUps = new RLLP_OppRollup();
        rlpUps.rollupAccounts(accountsMap);
        rlpUps.rollupContacts(contactsMap);

        RLLP_OppPartialSoftCreditRollup.rollupPartialSoftCredits(contactsMap.values());

        gau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = :GAU_NAME LIMIT 1];
        ALLO_Rollup_SCHED allocRlp = new ALLO_Rollup_SCHED(gau.Id);
        allocRlp.runRollups();

        npe03__Recurring_Donation__c rd = [SELECT Id FROM npe03__Recurring_Donation__c WHERE Name = :RD_NAME LIMIT 1];
        RD_RecurringDonations.updateRecurringDonationOnOppChange(new Set<Id>{ rd.Id }, null);
    }

    /** *****************************************************************************************
    * @description Execute the Legacy Rollups for the Account and Contact objects
    */
    public static void executeCustomizableRollups() {
        Customizable_Rollup_Settings__c cs = Customizable_Rollup_Settings__c.getOrgDefaults();
        cs.Customizable_Rollups_Enabled__c = true;
        cs.Rollups_Contact_SkewMode_Batch_Size__c = 500;
        cs.Rollups_Account_SkewMode_Batch_Size__c = 500;
        cs.Rollups_GAU_Batch_Size__c = 500;
        update cs;

        clearTargetRecords();

        accounts = [SELECT Id, Name FROM Account WHERE Site = :TEST_SITE_NAME];
        contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Account.Site = :TEST_SITE_NAME];
        gau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = :GAU_NAME LIMIT 1];

        List<Id> acctIds = new List<Id>((new Map<Id, Account>(accounts)).keySet());
        List<Id> contactIds = new List<Id>((new Map<Id, Contact>(contacts)).keySet());

        asyncExecuteCustomizableRollups(acctIds, contactIds);

        CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.GAU,
                CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, new List<Id>{ gau.Id }, null);
        CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit,
                CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode, contactIds, null);
        CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit,
                CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, acctIds, null);
        CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit,
                CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, acctIds, null);

    }

    /** @description Move the rollup of Account & Contacts to an async process just to avoid governor limit issues */
    @future
    private static void asyncExecuteCustomizableRollups(List<Id> acctIds, List<Id> contactIds) {
        CRLP_RollupQueueable.runRollupsForIds(acctIds);
        CRLP_RollupQueueable.runRollupsForIds(contactIds);
        npe03__Recurring_Donation__c rd = [SELECT Id FROM npe03__Recurring_Donation__c WHERE Name = :RD_NAME LIMIT 1];
        CRLP_RollupQueueable.runRollupsForIds(new List<Id>{rd.Id});
    }

    /** *****************************************************************************************
    * @description Validate Account and Contact Rollup results
    */
    public static void validateRollups() {
        Customizable_Rollup_Settings__c cs = Customizable_Rollup_Settings__c.getOrgDefaults();

        String acctSOQL = CRLP_Query_SEL.buildObjectQueryForRollup(Account.SObjectType);
        acctSOQL += ' WHERE Site = :TEST_SITE_NAME';
        acctSOQL = acctSOQL.replace('Id,', 'Id,Name,');
        accounts = Database.query(acctSOQL);

        Account orgAcct = [SELECT Id, Name FROM Account WHERE npe01__SYSTEMIsIndividual__c = false
        AND Site = :TEST_SITE_NAME AND Name != :ACCOUNT_NAME_ASC LIMIT 1];
        Id orgAcctId = orgAcct.Id;
        Contact orgContactSC = [SELECT Id, AccountId FROM Contact WHERE FirstName = :ORG_CONTACT_NAME LIMIT 1];
        Integer countAccts = [SELECT Count()
        FROM Account
        WHERE Site = :TEST_SITE_NAME
        AND Id != :orgAcctId
        AND Name != :ACCOUNT_NAME_ASC
        AND Name != :ACCOUNT_NAME_RD];

        for (Account a : accounts) {
            // The organization account will only have a single donation
            if (a.Name == ACCOUNT_NAME_RD) {
                // No need to validate rollups on the Recurring Donations Account
                continue;

            } else if (a.Name == ACCOUNT_NAME_ASC) {
                // Validate Account Soft Credits rollup to one Account, only when CRLPs is enabled
                if (cs.Customizable_Rollups_Enabled__c == true) {
                    assertValue((ACCOUNT_SOFT_CREDIT_BASE_AMOUNT * CLOSED_OPP_COUNT_PER_ACCT * countAccts) , (Double) a.get('TEST_Acc_Soft_Credit_Total__c'), a.Id + ' Acccount.TEST_Acc_Soft_Credit_Total__c should be');
                    assertValue(ACCOUNT_SOFT_CREDIT_BASE_AMOUNT * 2, (Double) a.get('TEST_Acc_Soft_Credit_Largest_Amt__c'), a.Id + ' Acccount.TEST_Acc_Soft_Credit_Largest_Amt__c should be');
                }

            } else if (a.Id != orgAcct.Id) {
                // If the Account is not an Organization Account

                assertValue(ROLLUP_TOTAL_WON_AMOUNT, a.npo02__TotalOppAmount__c, a.Id + ' Account.npo02__TotalOppAmount__c should be');
                assertValue(ROLLUP_TOTAL_WON_COUNT, a.npo02__NumberOfClosedOpps__c, 'Account.npo02__NumberOfClosedOpps__c should be');
                assertValue(ROLLUP_AVERAGE, a.npo02__AverageAmount__c.divide(1, 2, System.RoundingMode.HALF_UP), 'Account.npo02__AverageAmount__c should be');
                assertValue(ROLLUP_LARGEST, a.npo02__LargestAmount__c, 'Account.npo02__LargestAmount__c should be');
                assertValue(ROLLUP_SMALLEST, a.npo02__SmallestAmount__c, 'Account.npo02__SmallestAmount__c should be');
                assertValue(ROLLUP_BEST_YEAR, a.npo02__Best_Gift_Year__c, 'Account.npo02__Best_Gift_Year__c should be');
                assertValue(ROLLUP_FIRSTDATE, a.npo02__FirstCloseDate__c, 'Account.npo02__FirstCloseDate__c should be');
                assertValue(ROLLUP_LASTTDATE, a.npo02__LastCloseDate__c, 'Account.npo02__LastCloseDate__c should be');
                assertValue(ROLLUP_TOTAL_LASTYEAR, a.npo02__OppAmountLastYear__c, 'Account.npo02__OppAmountLastYear__c should be');

                assertValue(MEMBERSHIP_FIRST_DATE, a.npo02__MembershipJoinDate__c, 'Account.npo02__MembershipJoinDate__c should be');
                assertValue(MEMBERSHIP_FIRST_DATE.addYears(4).addDays(-1), a.npo02__MembershipEndDate__c, 'Account.npo02__MembershipEndDate__c should be');
                assertValue(4, a.npo02__NumberOfMembershipOpps__c, 'Account.npo02__NumberOfMembershipOpps__c should be');

                // CUSTOM ROLL-UP TESTING ONLY FOR THE NEW ROLLUPS ENGINE
                if (cs.Customizable_Rollups_Enabled__c == true) {
                    // Test soft credit to Account
                    if (a.Id != orgContactSC.AccountId) {
                        assertValue(ROLLUP_TOTAL_WON_AMOUNT, (Double) a.get('TEST_Soft_Credit_Total__c'), a.Id + ' Acccount.TEST_Soft_Credit_Total__c should be');
                    } else {
                        assertValue(ROLLUP_TOTAL_WON_AMOUNT + ORG_DONATION_AMT, (Double) a.get('TEST_Soft_Credit_Total__c'), a.Id + ' Acccount.TEST_Soft_Credit_Total__c should be');
                    }
                    // Total Payments and Total Write-Offs
                    assertValue(ROLLUP_TOTAL_PAYMENT_AMOUNT, (Double) a.get('TEST_Total_Payments__c'), a.Id + ' Acccount.TEST_Total_Payments__c should be');
                    assertValue(ROLLUP_TOTAL_WRITEOFF_AMOUNT, (Double) a.get('TEST_Total_Writeoffs__c'), a.Id + ' Acccount.TEST_Total_Writeoffs__c should be');

                }
            } else if (a.Id == orgAcct.Id) {
                // Organization Account Rollup
                assertValue(ORG_DONATION_AMT, a.npo02__TotalOppAmount__c, a.Id + ' Account.npo02__TotalOppAmount__c should be');
                assertValue(1, a.npo02__NumberOfClosedOpps__c, a.Id + ' Account.npo02__TotalOppAmount__c should be');
            }
        }

        String contactSOQL = CRLP_Query_SEL.buildObjectQueryForRollup(Contact.SObjectType).split(' FROM ')[0] +
                ', Account.npe01__One2OneContact__c FROM Contact ' +
                ' WHERE Account.Site = :TEST_SITE_NAME';
        contactSOQL = contactSOQL.replace('Id,', 'Id,Account.Name,');
        contacts = Database.query(contactSOQL);

        for (Contact c : contacts) {
            // The organization account will only have a single donation
            if (c.Account.Name == ACCOUNT_NAME_RD) {
                // No need to validate rollups on the Recurring Donations Account Contact
                continue;

            } else if (c.Account.npe01__One2OneContact__c == c.Id) {
                // Hard Credit
                assertValue(ROLLUP_TOTAL_WON_AMOUNT, c.npo02__TotalOppAmount__c, 'Contact.npo02__TotalOppAmount__c should be');
                assertValue(ROLLUP_TOTAL_WON_COUNT, c.npo02__NumberOfClosedOpps__c, 'Contact.npo02__NumberOfClosedOpps__c should be');
                assertValue(ROLLUP_AVERAGE, c.npo02__AverageAmount__c.divide(1, 2, System.RoundingMode.HALF_UP), 'Contact.npo02__AverageAmount__c should be');
                assertValue(ROLLUP_LARGEST, c.npo02__LargestAmount__c, 'Contact.npo02__LargestAmount__c should be');
                assertValue(ROLLUP_SMALLEST, c.npo02__SmallestAmount__c, 'Contact.npo02__SmallestAmount__c should be');
                assertValue(ROLLUP_BEST_YEAR, c.npo02__Best_Gift_Year__c, 'Contact.npo02__Best_Gift_Year__c should be');
                assertValue(ROLLUP_FIRSTDATE, c.npo02__FirstCloseDate__c, 'Contact.npo02__FirstCloseDate__c should be');
                assertValue(ROLLUP_LASTTDATE, c.npo02__LastCloseDate__c, 'Contact.npo02__LastCloseDate__c should be');
                assertValue(ROLLUP_TOTAL_LASTYEAR, c.npo02__OppAmountLastYear__c, 'Contact.npo02__OppAmountLastYear__c should be');

                assertValue(0, c.npo02__Soft_Credit_Total__c, 'Contact.npo02__Soft_Credit_Total__c should be');

                assertValue(MEMBERSHIP_FIRST_DATE, c.npo02__MembershipJoinDate__c, 'Contact.npo02__MembershipJoinDate__c should be');
                assertValue(MEMBERSHIP_FIRST_DATE.addYears(4).addDays(-1), c.npo02__MembershipEndDate__c, 'Contact.npo02__MembershipEndDate__c should be');
                assertValue(MEMBERSHIP_COUNT, c.npo02__NumberOfMembershipOpps__c, 'Contact.npo02__NumberOfMembershipOpps__c should be');
                assertValue('Bronze', c.npo02__LastMembershipLevel__c, 'Contact.npo02__LastMembershipLevel__c should be');

            } else {
                // Soft Credit
                if (c.Id != orgContactSC.Id) {
                    assertValue(ROLLUP_TOTAL_WON_AMOUNT, c.npo02__Soft_Credit_Total__c, c.Id + ' Contact.npo02__Soft_Credit_Total__c should be');
                    assertValue(ROLLUP_TOTAL_WON_COUNT, c.Number_of_Soft_Credits__c, c.Id + ' Contact.Number_of_Soft_Credits__c should be');
                    assertValue(ROLLUP_LARGEST, c.Largest_Soft_Credit_Amount__c, 'Contact.Largest_Soft_Credit_Amount__c should be');
                    assertValue(ROLLUP_FIRSTDATE, c.First_Soft_Credit_Date__c, 'Contact.First_Soft_Credit_Date__c should be');
                    assertValue(ROLLUP_LASTTDATE, c.Last_Soft_Credit_Date__c, 'Contact.Last_Soft_Credit_Date__c should be');
                    assertValue(ROLLUP_TOTAL_LASTYEAR, c.npo02__Soft_Credit_Last_Year__c, 'Contact.npo02__Soft_Credit_Last_Year__c should be');
                } else {
                    assertValue(ROLLUP_TOTAL_WON_AMOUNT + ORG_DONATION_AMT, c.npo02__Soft_Credit_Total__c, c.Id + ' Org Contact.npo02__Soft_Credit_Total__c should be');
                    assertValue(ROLLUP_TOTAL_WON_COUNT + 1, c.Number_of_Soft_Credits__c, c.Id + ' Contact.Number_of_Soft_Credits__c should be');
                    assertValue(ORG_DONATION_AMT, c.Largest_Soft_Credit_Amount__c, 'Contact.Largest_Soft_Credit_Amount__c should be');
                }
                assertValue(0, c.npo02__TotalOppAmount__c, 'Contact.npo02__TotalOppAmount__c should be');

                assertValue(null, c.npo02__MembershipJoinDate__c, 'Contact.npo02__MembershipJoinDate__c should be');
                assertValue(null, c.npo02__MembershipEndDate__c, 'Contact.npo02__MembershipEndDate__c should be');
                assertValue(0, c.npo02__NumberOfMembershipOpps__c, 'Contact.npo02__NumberOfMembershipOpps__c should be');
                assertValue(null, c.npo02__LastMembershipLevel__c, 'Contact.npo02__LastMembershipLevel__c should be');
            }

        }

        String gauSOQL = CRLP_Query_SEL.buildObjectQueryForRollup(General_Accounting_Unit__c.SObjectType) + ' WHERE Name = :GAU_NAME LIMIT 1';
        gau = Database.query(gauSOQL);
        assertValue(ALLOC_TOTAL_AMOUNT, gau.Total_Allocations__c, 'Total_Allocations__c should be');
        assertValue(ALLOC_TOTAL_COUNT, gau.Total_Number_of_Allocations__c, 'Total_Number_of_Allocations__c should be');
        assertValue(ALLOC_AVERAGE.intValue(), (gau.Average_Allocation__c != null ? gau.Average_Allocation__c.intValue() : null), 'Average_Allocation__c should be');


        String rdSOQL = CRLP_Query_SEL.buildObjectQueryForRollup(npe03__Recurring_Donation__c.SObjectType) + ' WHERE Name = :RD_NAME LIMIT 1';
        npe03__Recurring_Donation__c rd = Database.query(rdSOQL);
        assertValue(12, rd.npe03__Total_Paid_Installments__c, 'npe03__Total_Paid_Installments__c should be');
        assertValue(RD_AMOUNT_USD * 12, rd.npe03__Paid_Amount__c, 'npe03__Paid_Amount__c should be');
        assertValue(Date.Today().addMonths(-1), rd.npe03__Last_Payment_Date__c, 'npe03__Last_Payment_Date__c should be');

        if (!errorsList.isEmpty()) {
            throw new ValidationException('\n' + String.join(errorsList, '\n'));
        }
        System.debug(LoggingLevel.Error, '>>> ALL VALIDATIONS PASSED <<<');
    }

    private static List<String> errorsList = new List<String>();

    /** *****************************************************************************************
     * @description Assertion test methods with overloads
     */
    private static void assertValue(Decimal expected, Decimal actual, String message) {
        if (expected != (actual == null ? 0 : actual)) {
            errorsList.add('VALIDATION: ' + message + ' ' + expected + ', but actual is ' + actual);
        }
    }
    private static void assertValue(String expected, String actual, String message) {
        if (expected != actual) {
            errorsList.add('VALIDATION: ' + message + ' ' + expected + ', but actual is ' + actual);
        }
    }
    private static void assertValue(Date expected, Date actual, String message) {
        if (expected != actual) {
            errorsList.add('VALIDATION: ' + message + ' ' + expected + ', but actual is ' + actual);
        }
    }
    public class ValidationException extends Exception {}

// ========================================================================================================
// PRIVATE METHODS TO CREATE THE TESTING DATA
// ========================================================================================================

    private static void createAccountsAndContacts() {
        Account a1 =  new Account(
                Name = 'CRLP TEST ACCOUNT 1',
                Site = TEST_SITE_NAME,
                RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Household Account')
        );
        Account a2 =  new Account(
                Name = 'CRLP TEST ACCOUNT 2',
                Site = TEST_SITE_NAME,
                RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Household Account')
        );

        Account a3 =  new Account(
                Name = ACCOUNT_NAME_RD,
                Site = TEST_SITE_NAME,
                RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Household Account')
        );

        Account a4 =  new Account(
                Name = ACCOUNT_NAME_ORG,
                Site = TEST_SITE_NAME,
                RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Organization')
        );

        Account a5 =  new Account(
                Name = ACCOUNT_NAME_ASC,
                Site = TEST_SITE_NAME,
                RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Organization')
        );

        insert new List<Account>{a1, a2, a3, a4, a5};
        accounts = [SELECT Id, Name FROM Account WHERE Site = :TEST_SITE_NAME AND npe01__SYSTEMIsIndividual__c = true];

        // Two Contacts on Household 1
        Contact c1 = new Contact(
                FirstName = 'CRLPTEST-1',
                LastName = 'Household1',
                AccountId = a1.Id
        );
        Contact c2 = new Contact(
                FirstName = 'CRLPTEST-2',
                LastName = 'Household1',
                AccountId = a1.Id
        );
        // Three Contacts on Household 2
        Contact c3 = new Contact(
                FirstName = 'CRLPTEST-1',
                LastName = 'Household2',
                AccountId = a2.Id
        );
        Contact c4 = new Contact(
                FirstName = 'CRLPTEST-2',
                LastName = 'Household2',
                AccountId = a2.Id
        );
        Contact c5 = new Contact(
                FirstName = ORG_CONTACT_NAME,
                LastName = 'Household2',
                AccountId = a2.Id
        );

        // One Contacts on the RD Household Accouunt
        Contact c6 = new Contact(
                FirstName = 'CRLPTEST-1',
                LastName = 'RDHousehold',
                AccountId = a3.Id
        );

        insert new List<Contact>{c1, c2, c3, c4, c5, c6};
        contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Account.Site = :TEST_SITE_NAME];
        a1.npe01__One2OneContact__c = c1.Id;
        a2.npe01__One2OneContact__c = c3.Id;
        a3.npe01__One2OneContact__c = c6.Id;
        update new List<Account>{a1, a2, a3};
    }

    private static void createGAU() {
        gau = new General_Accounting_Unit__c(
                Name = GAU_NAME,
                Active__c = true
        );
        insert gau;
    }

    /** *****************************************************************************************
     * @description Create test Opportunity records:
     *  - 450 Closed Won Donations
     *  - 50 Closed Lost Donations
     *  - 4 Memberships
     *  - All with Allocations, Payments and OCR's
     */
    @future
    private static void createOpportunitiesASync() {
        List<Opportunity> opps = new List<Opportunity>();
        List<Allocation__c> allocs = new List<Allocation__c>();
        List<Account_Soft_Credit__c> accSCs = new List<Account_Soft_Credit__c>();

        accounts = [SELECT Id, Name FROM Account WHERE Site = :TEST_SITE_NAME AND npe01__SYSTEMIsIndividual__c = true];
        contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Account.Site = :TEST_SITE_NAME];
        gau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = :GAU_NAME LIMIT 1];

        for (Integer na=0; na<accounts.size(); na++) {
            // Don't create opps on the Recurring Donations test account
            if (accounts[na].Name == ACCOUNT_NAME_RD) {
                continue;
            }

            // Don't create opps on the ASC test account
            if (accounts[na].Name == ACCOUNT_NAME_ASC ) {
                continue;
            }

            Date nextDate = ROLLUP_FIRSTDATE;
            Map<Integer, Integer> countByYear = new Map<Integer, Integer>();
            for (Integer no = 0; no < OPP_COUNT_PER_ACCT; no++) {
                Opportunity opp = new Opportunity(
                        Name = 'CRLP TEST OPP ' + no,
                        AccountId = accounts[na].Id,
                        Amount = OPPORTUNITY_AMOUNT,
                        RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Opportunity.SObjectType, 'Donation'),
                        StageName = (no < CLOSED_OPP_COUNT_PER_ACCT ? closedWonStage : closedLostStage),
                        CloseDate = nextDate
                );
                if (UserInfo.isMultiCurrencyOrganization()) {
                    opp.put('CurrencyIsoCode', 'CAD');
                }
                opps.add(opp);

                Integer theYear = nextDate.year();
                if (!countByYear.containsKey(theYear)) {
                    countByYear.put(theYear, 0);
                }
                countByYear.put(theYear, countByYear.get(theYear) + 1);

                if (countByYear.get(theYear) == 150 && theYear != 2017) {
                    nextDate = Date.newInstance(theYear+1, 1, 1);
                }
                nextDate = nextDate.addDays(2);
            }

            nextDate = MEMBERSHIP_FIRST_DATE;
            for (Integer no=0;no<4;no++) {
                Opportunity opp = new Opportunity(
                        Name = 'Membership Test' + no,
                        AccountId = accounts[na].Id,
                        Amount = MEMBERSHIP_AMOUNT,
                        RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Opportunity.SObjectType, 'Membership'),
                        StageName = closedWonStage,
                        CloseDate = nextDate,
                        npe01__Member_Level__c = 'Bronze',
                        npe01__Membership_Origin__c = 'New',
                        npe01__Membership_Start_Date__c = nextDate,
                        npe01__Membership_End_Date__c = nextDate.addYears(1).addDays(-1)
                );
                opps.add(opp);
                nextDate = nextDate.addYears(1);
            }
        }

        Account orgAcct = [SELECT Id, Name FROM Account WHERE npe01__SYSTEMIsIndividual__c = false
        AND Site = :TEST_SITE_NAME LIMIT 1];
        Contact orgContactSC = [SELECT Id FROM Contact WHERE FirstName = :ORG_CONTACT_NAME LIMIT 1];

        // create one closed won Organization opportunity to ensure it's not included in the Contact Hard Credit rollups
        Date orgDonationDate = Date.Today().addDays(-30);
        opps.add(new Opportunity (
                Name = 'Test Org Opp',
                AccountId = orgAcct.Id,
                Amount = ORG_DONATION_AMT,
                CloseDate = orgDonationDate,
                StageName = closedWonStage,
                Primary_Contact__c = orgContactSC.Id,
                RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Opportunity.SObjectType, 'Donation'),
                npe01__Do_Not_Automatically_Create_Payment__c = true
        ));

        // Disable the legacy rollup triggers before this
        for (Trigger_Handler__c th : TDTM_Config_API.getCachedRecords()) {
            if (th.Class__c == 'RLLP_OppRollup_TDTM' || th.Class__c == 'CRLP_Rollup_TDTM' ||
                    th.Class__c == 'ALLO_Allocations_TDTM' || th.Class__c == 'RD_RecurringDonations_Opp_TDTM') {
                th.Active__c = false;
            }
        }

        insert opps;

        // Change the OCR Role on the org donation so that it will roll up as a soft credit.
        OpportunityContactRole orgOCR = [SELECT Id, Role FROM OpportunityContactRole
        WHERE Opportunity.AccountId = :orgAcct.Id AND IsPrimary = True LIMIT 1];
        orgOCR.Role = 'Soft Credit';    // force to this because it's a good common value that should be in the filters
        update orgOCR;

        // Create Allocations for all Opps except the Organization one.
        for (Opportunity opp : opps) {
            if (opp.AccountId != orgAcct.Id) {
                Allocation__c alloc = new Allocation__c(
                        General_Accounting_Unit__c = gau.Id,
                        Opportunity__c = opp.Id,
                        Amount__c = opp.Amount
                );
                if (UserInfo.isMultiCurrencyOrganization()) {
                    alloc.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
                }
                allocs.add(alloc);
            }
        }
        insert allocs;

        // Create Account Soft credits for all Opps except the Organization one and the Membership ones
        Account accForSoftCredits = [SELECT Id FROM Account WHERE Name = :ACCOUNT_NAME_ASC LIMIT 1];
        Id membershipRTId = UTIL_RecordTypes.getRecordTypeId(Opportunity.SObjectType, 'Membership');
        for (Integer i=0; i<opps.size(); i++) {
            Opportunity opp = opps[i];
            if (opp.AccountId != orgAcct.Id
                    && opp.RecordTypeId != membershipRTId
                    && opp.StageName == closedWonStage) {
                Account_Soft_Credit__c accSC = new Account_Soft_Credit__c(
                        Account__c = accForSoftCredits.Id,
                        Opportunity__c = opp.Id,
                        Amount__c = ACCOUNT_SOFT_CREDIT_AMOUNT,
                        Role__c = ACCOUNT_SOFT_CREDIT_ROLE_A
                );
                if (UserInfo.isMultiCurrencyOrganization()) {
                    accSC.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
                }
                accSCs.add(accSC);
            }
        }
        insert accSCs;

        accSCs = [SELECT Id, Amount__c FROM Account_Soft_Credit__c WHERE Account__r.Name = :ACCOUNT_NAME_ASC];
        //give one AccSC a larger amount in order to validate a LARGEST rollup
        accSCs[0].Amount__c = accSCs[0].Amount__c*2;
        //give one AccSC a different role in order to validate filter group exclusion
        accSCs[1].Role__c = ACCOUNT_SOFT_CREDIT_ROLE_B;
        update accSCs;

        Contact rdContact = [SELECT Id, AccountId FROM Contact WHERE Account.Name = :ACCOUNT_NAME_RD LIMIT 1];
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
                Name = RD_NAME,
                npe03__Installments__c = 12,
                npe03__Contact__c = rdContact.Id,
                /*npe03__Organization__c = rdContact.AccountId,*/
                npe03__Amount__c = RD_AMOUNT_USD,
                npe03__Installment_Period__c = System.label.npe03.RecurringDonationInstallmentPeriodMonthly,
                npe03__Date_Established__c = Date.Today().addMonths(-12),
                npe03__Schedule_Type__c = System.label.npe03.RecurringDonationMultiplyValue,
                npe03__Open_Ended_Status__c = 'Open'
        );
        insert rd;

        // Close all the Recurring Donation Opportunities
        List<Opportunity> rdOpps = [SELECT Id FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.id
        AND CloseDate < TODAY];
        for (Opportunity o : rdOpps) {
            o.StageName = closedWonStage;
        }
        update rdOpps;
    }

    /** *****************************************************************************************
     * @description Reset all Rollup Target Fields on the Account and Contact object to null/zero
     */
    public static void clearTargetRecords() {
        String oppObjectName = UTIL_Describe.getObjectDescribe('Opportunity').getName();
        String pmtObjectName = UTIL_Describe.getObjectDescribe('npe01__OppPayment__c').getName();
        String pscObjectName = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c')).getName();

        accounts = [SELECT Id, Name FROM Account WHERE Site = :TEST_SITE_NAME];
        contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Account.Site = :TEST_SITE_NAME];
        gau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = :GAU_NAME LIMIT 1];

        // Contacts
        List<CRLP_Rollup> rollups = new List<CRLP_Rollup>();
        for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupsBySummaryType().get(Contact.SObjectType)) {
            rollups.add(new CRLP_Rollup(r));
        }

        List<SObject> empties = new List<SObject>();
        for (Contact c : contacts) {
            empties.add(CRLP_Rollup_SVC.createEmptyResultObject(c.Id, rollups));
        }
        update empties;

        // Accounts
        rollups = new List<CRLP_Rollup>();
        for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupsBySummaryType().get(Account.SObjectType)) {
            rollups.add(new CRLP_Rollup(r));
        }

        empties = new List<SObject>();
        for (Account a : accounts) {
            empties.add(CRLP_Rollup_SVC.createEmptyResultObject(a.Id, rollups));
        }
        update empties;

        // GAU
        rollups = new List<CRLP_Rollup>();
        for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupsBySummaryType().get(General_Accounting_Unit__c.SObjectType)) {
            rollups.add(new CRLP_Rollup(r));
        }

        empties = new List<SObject>();
        empties.add(CRLP_Rollup_SVC.createEmptyResultObject(gau.Id, rollups));
        update empties;

        npe03__Recurring_Donation__c rd = [SELECT Id FROM npe03__Recurring_Donation__c WHERE Name = :RD_NAME LIMIT 1];
        rd.npe03__Paid_Amount__c = null;
        rd.npe03__Total_Paid_Installments__c = null;
        rd.npe03__Last_Payment_Date__c = null;
        rd.npe03__Next_Payment_Date__c = null;
        update rd;
    }

    public static void createCustomRollups() {
        CRLP_RollupCMT.FilterGroup filterGroupPayments = new CRLP_RollupCMT.FilterGroup('TEMP: All Payments');
        filterGroupPayments.description = 'All Paid Payments regardless of Record Type';
        filterGroupPayments.recordName = 'NPSP_TEMP_Payments_Paid';

        CRLP_RollupCMT.FilterRule filterRulePaid = new CRLP_RollupCMT.FilterRule(filterGroupPayments.recordName, 'TEMP: Is Paid');
        filterRulePaid.recordName = 'NPSP_TEMP_Payments_Rule_Paid';
        filterRulePaid.objectName = npe01__OppPayment__c.SObjectType.getDescribe().getName();
        filterRulePaid.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        filterRulePaid.fieldName = 'npe01__Paid__c';
        filterRulePaid.value = 'true';
        filterGroupPayments.rules.add(filterRulePaid);

        CRLP_RollupCMT.FilterGroup filterGroupWrittenOff = new CRLP_RollupCMT.FilterGroup('TEMP: All WriteOffs');
        filterGroupWrittenOff.recordName = 'NPSP_TEMP_Payments_WrittenOff';
        filterGroupWrittenOff.description = 'All Written Off Payments regardless of Record Type';

        CRLP_RollupCMT.FilterRule filterRuleWrittenOff = new CRLP_RollupCMT.FilterRule(filterGroupWrittenOff.recordName, 'TEMP: Is Writeoff');
        filterRuleWrittenOff.recordName = 'NPSP_TEMP_Payments_Rule_WrittenOff';
        filterRuleWrittenOff.objectName = npe01__OppPayment__c.SObjectType.getDescribe().getName();
        filterRuleWrittenOff.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        filterRuleWrittenOff.fieldName = 'npe01__Written_Off__c';
        filterRuleWrittenOff.value = 'true';
        filterGroupWrittenOff.rules.add(filterRuleWrittenOff);

        CRLP_RollupCMT.Rollup rollupTotalPaid = new CRLP_RollupCMT.Rollup('UDR: Amount to Account.TotalPayments');
        rollupTotalPaid.recordName = 'NPSP_TEMP_Total_Payments_to_Account';
        rollupTotalPaid.filterGroupRecordName = filterGroupPayments.recordName;
        rollupTotalPaid.summaryObject = 'Account';
        rollupTotalPaid.summaryField = 'TEST_Total_Payments__c';
        rollupTotalPaid.detailObject = npe01__OppPayment__c.SObjectType.getDescribe().getName();
        rollupTotalPaid.detailField = 'npe01__Payment_Amount__c';
        rollupTotalPaid.amountObject = npe01__OppPayment__c.SObjectType.getDescribe().getName();
        rollupTotalPaid.amountField = 'npe01__Payment_Amount__c';
        rollupTotalPaid.dateObject = npe01__OppPayment__c.SObjectType.getDescribe().getName();
        rollupTotalPaid.dateField = 'npe01__Payment_Date__c';
        rollupTotalPaid.operation = CRLP_Operation.RollupType.SUM.name();
        rollupTotalPaid.isActive = true;

        CRLP_RollupCMT.Rollup rollupTotalWrittenOff = new CRLP_RollupCMT.Rollup('UDR: Amount to Account.TotalWriteOffs');
        rollupTotalWrittenOff.recordName = 'NPSP_TEMP_Total_Written_to_Account';
        rollupTotalWrittenOff.filterGroupRecordName = filterGroupWrittenOff.recordName;
        rollupTotalWrittenOff.summaryObject = 'Account';
        rollupTotalWrittenOff.summaryField = 'TEST_Total_Writeoffs__c';
        rollupTotalWrittenOff.detailObject = npe01__OppPayment__c.SObjectType.getDescribe().getName();
        rollupTotalWrittenOff.detailField = 'npe01__Payment_Amount__c';
        rollupTotalWrittenOff.amountObject = npe01__OppPayment__c.SObjectType.getDescribe().getName();
        rollupTotalWrittenOff.amountField = 'npe01__Payment_Amount__c';
        rollupTotalWrittenOff.dateObject = npe01__OppPayment__c.SObjectType.getDescribe().getName();
        rollupTotalWrittenOff.dateField = 'npe01__Payment_Date__c';
        rollupTotalWrittenOff.operation = CRLP_Operation.RollupType.SUM.name();
        rollupTotalWrittenOff.isActive = true;

        // Account-Level Contact Soft Credits
        CRLP_RollupCMT.Rollup rollupContactSoftCreditsToAccount = new CRLP_RollupCMT.Rollup('UDR: Contact Soft Credit Total to Account');
        rollupContactSoftCreditsToAccount.recordName = 'NPSP_TEMP_Total_ConSoftCredits_Account';
        rollupContactSoftCreditsToAccount.filterGroupRecordName = 'NPSP_ClosedWon_Opps_SC';
        rollupContactSoftCreditsToAccount.summaryObject = 'Account';
        rollupContactSoftCreditsToAccount.summaryField = 'TEST_Soft_Credit_Total__c';
        rollupContactSoftCreditsToAccount.detailObject = Partial_Soft_Credit__c.SObjectType.getDescribe().getName();
        rollupContactSoftCreditsToAccount.detailField = 'Amount__c';
        rollupContactSoftCreditsToAccount.amountObject = Partial_Soft_Credit__c.SObjectType.getDescribe().getName();
        rollupContactSoftCreditsToAccount.amountField = 'Amount__c';
        rollupContactSoftCreditsToAccount.dateObject = Opportunity.SObjectType.getDescribe().getName();
        rollupContactSoftCreditsToAccount.dateField = 'CloseDate';
        rollupContactSoftCreditsToAccount.operation = CRLP_Operation.RollupType.SUM.name();
        rollupContactSoftCreditsToAccount.isActive = true;

        //Filter Group/Rule for Account Soft Credits
        CRLP_RollupCMT.FilterGroup filterGroupInfluencerAccSC = new CRLP_RollupCMT.FilterGroup('TEMP: Account Soft Credits Group');
        filterGroupInfluencerAccSC.description = 'All Paid Payments regardless of Record Type';
        filterGroupInfluencerAccSC.recordName = 'NPSP_TEMP_AccSC_Group_Influencer';

        CRLP_RollupCMT.FilterRule filterRuleInfluencer = new CRLP_RollupCMT.FilterRule(filterGroupPayments.recordName, 'TEMP: Influencer');
        filterRuleInfluencer.recordName = 'NPSP_TEMP_AccSC_Influencer';
        filterRuleInfluencer.objectName = Account_Soft_Credit__c.SObjectType.getDescribe().getName();
        filterRuleInfluencer.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        filterRuleInfluencer.fieldName = 'Role__c';
        filterRuleInfluencer.value = ACCOUNT_SOFT_CREDIT_ROLE_A;
        filterGroupInfluencerAccSC.rules.add(filterRuleInfluencer);

        // Account Soft Credits
        CRLP_RollupCMT.Rollup rollupAccountSoftCreditSum = new CRLP_RollupCMT.Rollup('UDR: Account Soft Credit Sum');
        rollupAccountSoftCreditSum.recordName = 'NPSP_TEMP_Total_AccSoftCredits_Account';
        rollupAccountSoftCreditSum.filterGroupRecordName = filterGroupInfluencerAccSC.recordName;
        rollupAccountSoftCreditSum.summaryObject = 'Account';
        rollupAccountSoftCreditSum.summaryField = 'TEST_Acc_Soft_Credit_Total__c';
        rollupAccountSoftCreditSum.detailObject = Account_Soft_Credit__c.SObjectType.getDescribe().getName();
        rollupAccountSoftCreditSum.detailField = 'Amount__c';
        rollupAccountSoftCreditSum.amountObject = Account_Soft_Credit__c.SObjectType.getDescribe().getName();
        rollupAccountSoftCreditSum.amountField = 'Amount__c';
        rollupAccountSoftCreditSum.dateObject = Opportunity.SObjectType.getDescribe().getName();
        rollupAccountSoftCreditSum.dateField = 'CloseDate';
        rollupAccountSoftCreditSum.operation = CRLP_Operation.RollupType.SUM.name();
        rollupAccountSoftCreditSum.isActive = true;

        // Account Soft Credits
        CRLP_RollupCMT.Rollup rollupAccountSoftCreditLargest = new CRLP_RollupCMT.Rollup('UDR: Account Soft Credit Largest Amount');
        rollupAccountSoftCreditLargest.recordName = 'NPSP_TEMP_Last_AccSoftCredits_Account';
        rollupAccountSoftCreditLargest.filterGroupRecordName = filterGroupInfluencerAccSC.recordName;
        rollupAccountSoftCreditLargest.summaryObject = 'Account';
        rollupAccountSoftCreditLargest.summaryField = 'TEST_Acc_Soft_Credit_Largest_Amt__c';
        rollupAccountSoftCreditLargest.detailObject = Account_Soft_Credit__c.SObjectType.getDescribe().getName();
        rollupAccountSoftCreditLargest.detailField = 'Amount__c';
        rollupAccountSoftCreditLargest.amountObject = Account_Soft_Credit__c.SObjectType.getDescribe().getName();
        rollupAccountSoftCreditLargest.amountField = 'Amount__c';
        rollupAccountSoftCreditLargest.dateObject = Opportunity.SObjectType.getDescribe().getName();
        rollupAccountSoftCreditLargest.dateField = 'CloseDate';
        rollupAccountSoftCreditLargest.operation = CRLP_Operation.RollupType.LARGEST.name();
        rollupAccountSoftCreditLargest.isActive = true;

        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(new List<CRLP_RollupCMT.FilterGroup> {
                filterGroupPayments,
                filterGroupWrittenOff,
                filterGroupInfluencerAccSC });
        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(new List<CRLP_RollupCMT.Rollup>{
                rollupTotalPaid,
                rollupTotalWrittenOff,
                rollupContactSoftCreditsToAccount,
                rollupAccountSoftCreditSum,
                rollupAccountSoftCreditLargest });
        System.debug(CRLP_ConfigBuilder_SVC.deployedQueuedMetadataTypes());
    }

    /** Utility Methods copied from the Unit Test Data Builder class **/

    private static String closedWonStage {
        get {
            if (closedWonStage == null) {
                List<OpportunityStage> closedWonStages = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsWon = true];
                if (closedWonStages.size() > 0) {
                    closedWonStage = closedWonStages[0].MasterLabel;
                }
            }
            return closedWonStage;
        } private set;
    }
    private static String closedLostStage {
        get {
            if (closedLostStage == null) {
                List<OpportunityStage> closedLostStages = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true AND IsWon = false and IsClosed = true];
                if (closedLostStages.size() > 0) {
                    closedLostStage = closedLostStages[0].MasterLabel;
                }
            }
            return closedLostStage;
        } private set;
    }
}