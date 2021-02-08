/**
// Created by Michael Smith on 01/26/2018.
// Last Modified on 04/03/2020 to disable new RD2 functionality and to improve multi-currency support
//
// - Deploy this using the "deploy_rollup_testing" CCI flow. That will create the necessary target fields
//   on the Account object for Account-Contact Soft Credit, Account Soft Credit, and Payment Rollup testing.
//   It will also deploy this class into the org.
//
// - The most common issue with testing in this class is Membership Exclusion. Be sure to review the Legacy
//   and CustomizableRollups Filter Groups to ensure that either Membership Opps are include or excluded to
//   match the ROLLUPS_INCLUDES_MEMBERSHIP var setting below.
// - Specifically, in a new Scratch Org the "Membership" record type is not often set properly in Custom
//   Settings so when the Membership Filter Group is created there is no filter rule to limit Membership
//   Rollups to the Membership RT only. This will lead to the validateRollups() failing for the
//   Membership rollup in Customizable Rollups. The fix is to simply edit the Membership-Won Filter Group
//   to create a rule for Opportunity.RecordType=Membership.
//
// - ALL TESTS ARE CONDUCTED USING EXECUTE ANONYMOUS; EXECUTING ONE METHOD AT A TIME IN THE FOLLOWING ORDER:
// - The entire block below can be pasted into the ExecuteAnonymous window of DevConsole and then each task
//   run individually by highlighting the command and clicking [Execute Highlighted].
//
//
//   - STEP 1: Initial Setup - Delete any existing test data and recreate the data.
//   - NOTE: WAIT for the @Future job to finish before moving onto Step 2
//   CRLP_TEST_VALIDATE_ROLLUPS.deleteTestData();
//   CRLP_TEST_VALIDATE_ROLLUPS.createTestDataASync();
//
//   - STEP 2: ExecuteLegacyRollups will complete synchronously.
//   CRLP_TEST_VALIDATE_ROLLUPS.executeLegacyRollups();
//   - ValidateRollups will either throw an exception with errors or succeed. Click [Debug] in the Log View for details
//   CRLP_TEST_VALIDATE_ROLLUPS.validateRollups();
//
//   - STEP 3: ExecuteCustomizableRollups starts asynchronous batch jobs to complete the rollups.
//   - NOTE: WAIT for all the CRLP batch jobs to finish before running the validateRollups() method.
//   CRLP_TEST_VALIDATE_ROLLUPS.executeCustomizableRollups();
//   CRLP_TEST_VALIDATE_ROLLUPS.validateRollups();
//
//   - STEP 4: Optional: Delete the test data when done
//   CRLP_TEST_VALIDATE_ROLLUPS.deleteTestData();
*/
public class CRLP_TEST_VALIDATE_ROLLUPS {

    // ========================================================================
    // NOTE: When testing in a multi-currency org, set up CAD with this rate:
    private static final Double CURR_EXCHANGE_RATE = 2.0;
    // ========================================================================

    // THE FOLLOWING CAN BE ADJUSTED BY THE RUNNING USER DURING THE TESTING TO ADJUST FOR ORG CONFIGURATION
    private static final Boolean ROLLUPS_INCLUDES_MEMBERSHIP = true;
    private static final Boolean ALLOC_INCLUDES_MEMBERSHIP = true;
    private static final Boolean TEST_ACCOUNT_SOFT_CREDITS = true;

    private static final Integer NUM_HH_ACCOUNTS = 3; // this doesn't actually control the # of accounts created
    private static final Integer MAX_OPPS_PER_YEAR = 150;
    private static final Integer BASE_YEAR = Date.today().year()-3;
    private static final Date ROLLUP_FIRSTDATE = Date.newInstance(BASE_YEAR, 1, 2);
    private static final Date ROLLUP_LASTTDATE = (ROLLUPS_INCLUDES_MEMBERSHIP ?  Date.newInstance(BASE_YEAR+3, 6, 30) : Date.newInstance(BASE_YEAR+2,10,28));

    private static final Decimal ORG_DONATION_AMT = 5000;
    private static final Decimal BASE_AMOUNT_USD = 100;
    private static final Decimal RD_AMOUNT_USD = 150;
    private static final Integer OPP_COUNT_PER_ACCT = 500;
    private static final Integer CLOSED_OPP_COUNT_PER_ACCT = 450;

    private static final String ACCOUNT_NAME_RD = 'CRLP TEST ACCOUNT - RD';
    private static final String ACCOUNT_NAME_ORG = 'CRLP TEST ACCOUNT - ORG';
    private static final String ACCOUNT_NAME_ASC = 'CRLP TEST ACCOUNT - AccSoftCredit';
    private static final String TEST_SITE_NAME = 'CRLP TEST_DATA';
    private static final String ORG_CONTACT_NAME = 'CRLPTEST-ORG-DONATION'; // Household Contact that is Primary Contact on an Org Donation
    private static final String GAU_NAME = 'CRLP Default GAU';
    private static final String RD_NAME = 'CRLP TEST RD';
    private static final String ACCOUNT_SOFT_CREDIT_ROLE_A = 'Influencer';
    private static final String ACCOUNT_SOFT_CREDIT_ROLE_B = 'Donation Source';

    private static final Decimal OPPORTUNITY_AMOUNT_USD = BASE_AMOUNT_USD;
    private static final Decimal OPPORTUNITY_AMOUNT = (UserInfo.isMultiCurrencyOrganization() ? BASE_AMOUNT_USD*CURR_EXCHANGE_RATE : BASE_AMOUNT_USD);

    private static final Decimal ACCOUNT_SOFT_CREDIT_AMOUNT_USD = BASE_AMOUNT_USD / 2;
    private static final Decimal ACCOUNT_SOFT_CREDIT_AMOUNT = (UserInfo.isMultiCurrencyOrganization() ? ACCOUNT_SOFT_CREDIT_AMOUNT_USD * CURR_EXCHANGE_RATE : ACCOUNT_SOFT_CREDIT_AMOUNT_USD);

    private static final Date MEMBERSHIP_FIRST_DATE = Date.newInstance(BASE_YEAR,6,30);
    private static final Decimal MEMBERSHIP_AMOUNT = 25;
    private static final Decimal MEMBERSHIP_TOTAL = (MEMBERSHIP_AMOUNT*4);
    private static final Integer MEMBERSHIP_COUNT = 4;

    private static final Decimal ROLLUP_TOTAL_WON_AMOUNT = (CLOSED_OPP_COUNT_PER_ACCT * BASE_AMOUNT_USD)
            + (ROLLUPS_INCLUDES_MEMBERSHIP ? MEMBERSHIP_TOTAL : 0);
    private static final Decimal ROLLUP_TOTAL_WON_COUNT = CLOSED_OPP_COUNT_PER_ACCT
            + (ROLLUPS_INCLUDES_MEMBERSHIP ? MEMBERSHIP_COUNT : 0);
    private static final Decimal ROLLUP_TOTAL_LASTYEAR = (BASE_AMOUNT_USD * MAX_OPPS_PER_YEAR)
            + (ROLLUPS_INCLUDES_MEMBERSHIP ? MEMBERSHIP_AMOUNT : 0) ;
    private static final Decimal ROLLUP_AVERAGE = ROLLUP_TOTAL_WON_AMOUNT.divide(ROLLUP_TOTAL_WON_COUNT, 2, System.RoundingMode.HALF_UP);
    private static final Decimal ROLLUP_LARGEST = BASE_AMOUNT_USD;
    private static final Decimal ROLLUP_SMALLEST = (ROLLUPS_INCLUDES_MEMBERSHIP ? MEMBERSHIP_AMOUNT : BASE_AMOUNT_USD);
    private static final String ROLLUP_BEST_YEAR = BASE_YEAR.format().replace(',','');  // All 3 years have 150 donations, so 2015 is the first

    // Payment Rollups always include memberships, but will not inlcude the Org donation because it has no payment
    private static final Decimal ROLLUP_TOTAL_PAYMENT_AMOUNT = (CLOSED_OPP_COUNT_PER_ACCT * BASE_AMOUNT_USD) + MEMBERSHIP_TOTAL;
    private static final Decimal ROLLUP_TOTAL_WRITEOFF_AMOUNT = (OPP_COUNT_PER_ACCT-CLOSED_OPP_COUNT_PER_ACCT)*BASE_AMOUNT_USD;

    private static final Decimal ALLOC_TOTAL_AMOUNT = ((CLOSED_OPP_COUNT_PER_ACCT * BASE_AMOUNT_USD)
            + (ALLOC_INCLUDES_MEMBERSHIP ? MEMBERSHIP_TOTAL : 0)) * NUM_HH_ACCOUNTS;
    private static final Decimal ALLOC_TOTAL_COUNT = (CLOSED_OPP_COUNT_PER_ACCT
            + (ALLOC_INCLUDES_MEMBERSHIP ? MEMBERSHIP_COUNT : 0)) * NUM_HH_ACCOUNTS;
    private static final Decimal ALLOC_AVERAGE = ALLOC_TOTAL_AMOUNT.divide(ALLOC_TOTAL_COUNT, NUM_HH_ACCOUNTS);

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
            System.enqueueJob(new CreateDataQueueable(0) );
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
    * @description Execute the Customizable Rollups for the Account, Contact, GAU and RD objects
    */
    public static void executeCustomizableRollups() {
        Customizable_Rollup_Settings__c cs = Customizable_Rollup_Settings__c.getOrgDefaults();
        cs.Customizable_Rollups_Enabled__c = true;
        cs.Rollups_Contact_SkewMode_Batch_Size__c = 10; // 200;
        cs.Rollups_Account_SkewMode_Batch_Size__c = 10; // 200;
        cs.Rollups_GAU_Batch_Size__c = 100; // 200;
        cs.Rollups_Skew_Dispatcher_Batch_Size__c = 300; // 20;
        cs.Rollups_Limit_on_Attached_Opps_for_Skew__c = 250; // 50;
        update cs;

        clearTargetRecords();

        accounts = [SELECT Id, Name FROM Account WHERE Site = :TEST_SITE_NAME];
        contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Account.Site = :TEST_SITE_NAME];
        gau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = :GAU_NAME LIMIT 1];

        List<Id> acctIds = new List<Id>((new Map<Id, Account>(accounts)).keySet());
        List<Id> contactIds = new List<Id>((new Map<Id, Contact>(contacts)).keySet());

        // Executes Account, Contact and RD roll-ups real-time
        System.enqueueJob(new ExecuteCustomizableRollupsPart1(acctIds, contactIds));

        // Executes the following Skew & Non-Skew Mode async batch jobs
        CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.GAU,
                CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, new List<Id>{ gau.Id }, null);
        CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit,
                CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, contactIds, null);
    }

    /**
    * @description Move the rollup of Account & Contacts to an async process just to avoid governor
    * limit issues. Plus, to avoid lock errors on the Account object because of the two Account Soft
    * Credit jobs, these are split into chained Queueables
    */
    private class ExecuteCustomizableRollupsPart1 implements System.Queueable {
        List<Id> acctIds;
        List<Id> contactIds;

        public ExecuteCustomizableRollupsPart1(List<Id> acctIds, List<Id> contactIds) {
            this.acctIds = acctIds;
            this.contactIds = contactIds;
        }

        public void execute(QueueableContext qc) {

            npe03__Recurring_Donation__c rd = [SELECT Id FROM npe03__Recurring_Donation__c WHERE Name = :RD_NAME LIMIT 1];

            // Move this into the ASync process so it runs after the other Account job to avoid a Lock Error
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, acctIds, null);

            CRLP_RollupQueueable.runRollupsForIds(acctIds);
            CRLP_RollupQueueable.runRollupsForIds(contactIds);
            CRLP_RollupQueueable.runRollupsForIds(new List<Id>{rd.Id});

            // Run Skew Mode for AccountHardCredit against all Accounts in the org
            List<Account> allAccounts = [SELECT Id FROM Account];
            List<Id> allAcctIds = new List<Id>((new Map<Id, Account>(allAccounts)).keySet());
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, allAcctIds, null);

            /* - alternatively run the Account, Contact and RD hard credit rollups as SkewMode batch jobs
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, contactIds, null);
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, acctIds, null);
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.RecurringDonations,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, new List<Id>{rd.Id}, null);*/

            // Re-queue this same job so it can run the other Account Soft Credit type rollup
            System.enqueueJob(new ExecuteCustomizableRollupsPart2(acctIds));
        }
    }

    /**
     * @description Executes AccountContactSoftCredit rollups only - mainly to avoid lock errors
     */
    private class ExecuteCustomizableRollupsPart2 implements System.Queueable {

        private List<Id> acctIds = new List<Id>();

        public ExecuteCustomizableRollupsPart2(List<Id> acctIds) {
            this.acctIds = acctIds;
        }

        public void execute(QueueableContext qc) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit,
                CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, acctIds, null);
        }
    }

    /** *****************************************************************************************
    * @description Validate Account and Contact Rollup results
    */
    public static void validateRollups() {
        Customizable_Rollup_Settings__c cs = Customizable_Rollup_Settings__c.getOrgDefaults();

        String acctSOQL = CRLP_Query_SEL.buildObjectQueryForRollup(Account.SObjectType) + ' WHERE Site = :TEST_SITE_NAME';
        acctSOQL = acctSOQL.replace('Id,', 'Id,Name,');
        accounts = Database.query(acctSOQL);

        Account orgAcct = [
            SELECT Id, Name FROM Account
            WHERE npe01__SYSTEMIsIndividual__c = false
            AND Site = :TEST_SITE_NAME
            AND Name = :ACCOUNT_NAME_ORG
            LIMIT 1
        ];
        Id orgAcctId = orgAcct.Id;

        // Household Contact that is the Primary Contact on an Org Donation.
        Contact orgContactSC = [
            SELECT Id, AccountId
            FROM Contact
            WHERE FirstName = :ORG_CONTACT_NAME
            LIMIT 1
        ];

        Integer countAccts = [
            SELECT Count() FROM Account
            WHERE Site = :TEST_SITE_NAME
            AND Id != :orgAcctId
            AND Name != :ACCOUNT_NAME_ASC
            AND Name != :ACCOUNT_NAME_RD
        ];

        for (Account a : accounts) {

            // The organization account will only have a single donation
            if (a.Name == ACCOUNT_NAME_RD) {
                // No need to validate rollups on the Recurring Donations Account
                continue;

            } else if (a.Name == ACCOUNT_NAME_ASC) {

                // Validate Account Soft Credits rollup to one Account, only when CRLPs is enabled
                if (cs.Customizable_Rollups_Enabled__c == true && TEST_ACCOUNT_SOFT_CREDITS == true) {
                    assertValue((ACCOUNT_SOFT_CREDIT_AMOUNT_USD * CLOSED_OPP_COUNT_PER_ACCT * countAccts) + ACCOUNT_SOFT_CREDIT_AMOUNT_USD,
                        (Double) a.get('SC_Total__c'), a.Id + ' Acccount.SC_Total__c should be');
                    assertValue(ACCOUNT_SOFT_CREDIT_AMOUNT_USD * 2, (Double) a.get('Largest_SC_Amount__c'), a.Id + ' Acccount.Largest_SC_Amount__c should be');
                }

            } else if (a.Id != orgAcct.Id) {
                // If the Account is not an Organization Account

                assertValue(ROLLUP_TOTAL_WON_AMOUNT, a.npo02__TotalOppAmount__c, a.Id + ' Account.npo02__TotalOppAmount__c should be');
                assertValue(ROLLUP_TOTAL_WON_COUNT, a.npo02__NumberOfClosedOpps__c, 'Account.npo02__NumberOfClosedOpps__c should be');
                assertValue(ROLLUP_AVERAGE, a.npo02__AverageAmount__c?.divide(1, 2, System.RoundingMode.HALF_UP), 'Account.npo02__AverageAmount__c should be');
                assertValue(ROLLUP_LARGEST, a.npo02__LargestAmount__c, 'Account.npo02__LargestAmount__c should be');
                assertValue(ROLLUP_SMALLEST, a.npo02__SmallestAmount__c, 'Account.npo02__SmallestAmount__c should be');
                assertValue(ROLLUP_BEST_YEAR, a.npo02__Best_Gift_Year__c, 'Account.npo02__Best_Gift_Year__c should be');
                assertValue(ROLLUP_FIRSTDATE, a.npo02__FirstCloseDate__c, 'Account.npo02__FirstCloseDate__c should be');
                assertValue(ROLLUP_LASTTDATE, a.npo02__LastCloseDate__c, 'Account.npo02__LastCloseDate__c should be');
                assertValue(ROLLUP_TOTAL_LASTYEAR, a.npo02__OppAmountLastYear__c, 'Account.npo02__OppAmountLastYear__c should be');

                AggregateResult ag = [SELECT Count(Id) cnt, Sum(Amount) sum FROM Opportunity
                    WHERE AccountId = :a.Id
                    AND IsWon = TRUE
                    AND (CloseDate = LAST_N_DAYS:365 OR CloseDate > TODAY)];
                Integer countLastNDays = ((Decimal)ag.get('cnt')).intValue();
                Decimal sumLastNDays = (Decimal)ag.get('sum');
                assertValue(countLastNDays, a.npo02__OppsClosedLastNDays__c, a.Id + ' Account.npo02__OppsClosedLastNDays__c should be');
                assertValue(sumLastNDays, a.npo02__OppAmountLastNDays__c, a.Id + ' Account.npo02__OppAmountLastNDays__c should be');

                assertValue(MEMBERSHIP_FIRST_DATE, a.npo02__MembershipJoinDate__c, 'Account.npo02__MembershipJoinDate__c should be');
                assertValue(MEMBERSHIP_FIRST_DATE.addYears(4).addDays(-1), a.npo02__MembershipEndDate__c, 'Account.npo02__MembershipEndDate__c should be');
                assertValue(4, a.npo02__NumberOfMembershipOpps__c, 'Account.npo02__NumberOfMembershipOpps__c should be');

                // CUSTOM ROLL-UP TESTING ONLY FOR THE NEW ROLLUPS ENGINE
                if (cs.Customizable_Rollups_Enabled__c == true) {

                    // Total Payments and Total Write-Offs
                    assertValue(ROLLUP_TOTAL_PAYMENT_AMOUNT, (Double) a.get('Rollup_Total_Payments__c'), a.Id + ' Acccount.Rollup_Total_Payments__c should be');
                    assertValue(ROLLUP_TOTAL_WRITEOFF_AMOUNT, (Double) a.get('Rollup_Total_Writeoffs__c'), a.Id + ' Acccount.Rollup_Total_Writeoffs__c should be');

                    // Validate Account-Contact Soft Credits (via OpportunityContactRole.Contact.AccountId)
                    if (TEST_ACCOUNT_SOFT_CREDITS) {

                        if (a.Id == orgContactSC.AccountId) {
                            // This Account has a Contact that is referenced on an Org Donation
                            assertValue(ROLLUP_TOTAL_WON_AMOUNT + ORG_DONATION_AMT, (Double) a.get('AccConSC_Total_SCs__c'), a.Id + ' OrgCon Acccount.AccConSC_Total_SCs__c should be');
                            assertValue(ROLLUP_TOTAL_WON_COUNT + 1, (Double) a.get('AccConSC_Count__c'), a.Id + ' OrgCon Acccount.AccConSC_Count__c should be');

                        } else {

                            assertValue(ROLLUP_TOTAL_WON_AMOUNT, (Double) a.get('AccConSC_Total_SCs__c'), a.Id + ' Acccount.AccConSC_Total_SCs__c should be');
                            assertValue(ROLLUP_TOTAL_WON_COUNT, (Double) a.get('AccConSC_Count__c'), a.Id + ' Acccount.AccConSC_Count__c should be');
                        }

                    }

                }
            } else if (a.Id == orgAcct.Id) {

                // Organization Account Rollup
                assertValue(ORG_DONATION_AMT, a.npo02__TotalOppAmount__c, a.Id + ' Org Account.npo02__TotalOppAmount__c should be');
                assertValue(1, a.npo02__NumberOfClosedOpps__c, a.Id + ' Org Account.npo02__TotalOppAmount__c should be');
            }
        }

        String contactSOQL = CRLP_Query_SEL.buildObjectQueryForRollup(Contact.SObjectType).split(' FROM ')[0] +
                ', Account.npe01__One2OneContact__c FROM Contact ' +
                ' WHERE Account.Site = :TEST_SITE_NAME';
        contactSOQL = contactSOQL.replace('Id,', 'Id,Account.Name,');
        contacts = Database.query(contactSOQL);

        // The number of Opps in the last 365 days could vary slightly based on a few factors such as the
        // current date. As a result, it's safer to force a manual count and sum of the values to validate against.
        List<AggregateResult> agr = [SELECT Primary_Contact__c, Count(Id) cnt, Sum(Amount) sum FROM Opportunity
            WHERE IsWon = TRUE
            AND (CloseDate = LAST_N_DAYS:365 OR CloseDate > TODAY)
            GROUP BY Primary_Contact__c];
        Map<Id, Integer> countLastNDays = new Map<Id, Integer>();
        Map<Id, Decimal> sumLastNDays = new Map<Id, Decimal>();
        for (AggregateResult ag : agr) {
            countLastNDays.put((Id)ag.get('Primary_Contact__c'), ((Decimal)ag.get('cnt')).intValue());
            sumLastNDays.put((Id)ag.get('Primary_Contact__c'), (Decimal)ag.get('sum'));
        }

        for (Contact c : contacts) {

            // The organization account will only have a single donation
            if (c.Account.Name == ACCOUNT_NAME_RD) {
                // No need to validate rollups on the Recurring Donations Account Contact
                continue;

            } else if (c.Account.npe01__One2OneContact__c == c.Id) {

                // Hard Credit
                assertValue(ROLLUP_TOTAL_WON_AMOUNT, c.npo02__TotalOppAmount__c, 'Contact.npo02__TotalOppAmount__c should be');
                assertValue(ROLLUP_TOTAL_WON_COUNT, c.npo02__NumberOfClosedOpps__c, 'Contact.npo02__NumberOfClosedOpps__c should be');
                assertValue(ROLLUP_AVERAGE, c.npo02__AverageAmount__c?.divide(1, 2, System.RoundingMode.HALF_UP), 'Contact.npo02__AverageAmount__c should be');
                assertValue(ROLLUP_LARGEST, c.npo02__LargestAmount__c, 'Contact.npo02__LargestAmount__c should be');
                assertValue(ROLLUP_SMALLEST, c.npo02__SmallestAmount__c, 'Contact.npo02__SmallestAmount__c should be');
                assertValue(ROLLUP_BEST_YEAR, c.npo02__Best_Gift_Year__c, 'Contact.npo02__Best_Gift_Year__c should be');
                assertValue(ROLLUP_FIRSTDATE, c.npo02__FirstCloseDate__c, 'Contact.npo02__FirstCloseDate__c should be');
                assertValue(ROLLUP_LASTTDATE, c.npo02__LastCloseDate__c, 'Contact.npo02__LastCloseDate__c should be');
                assertValue(ROLLUP_TOTAL_LASTYEAR, c.npo02__OppAmountLastYear__c, 'Contact.npo02__OppAmountLastYear__c should be');

                assertValue(countLastNDays.get(c.Id), c.npo02__OppsClosedLastNDays__c, c.Id + ' Contact.npo02__OppsClosedLastNDays__c should be');
                assertValue(sumLastNDays.get(c.Id), c.npo02__OppAmountLastNDays__c, c.Id + ' Contact.npo02__OppAmountLastNDays__c should be');

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
                    assertValue(ROLLUP_TOTAL_WON_COUNT + 1, c.Number_of_Soft_Credits__c, c.Id + ' Org Contact.Number_of_Soft_Credits__c should be');
                    assertValue(ORG_DONATION_AMT, c.Largest_Soft_Credit_Amount__c, 'Org Contact.Largest_Soft_Credit_Amount__c should be');
                }
                assertValue(0, c.npo02__TotalOppAmount__c, 'Contact.npo02__TotalOppAmount__c should be');
                assertValue(OPPORTUNITY_AMOUNT_USD, (Double) c.get('First_Soft_Credit_Amount__c'), c.Id + ' Contact.First_Soft_Credit_Amount__c should be');

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
        assertValue(ALLOC_AVERAGE.intValue(), (gau.Average_Allocation__c != null ? gau.Average_Allocation__c?.intValue() : null), 'Average_Allocation__c should be');


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
            String msg = 'VALIDATION: ' + message + ' ' + expected + ', but actual is ' + actual;
            System.debug(msg);
            errorsList.add(msg);
        }
    }
    private static void assertValue(String expected, String actual, String message) {
        if (expected != actual) {
            String msg = 'VALIDATION: ' + message + ' ' + expected + ', but actual is ' + actual;
            System.debug(msg);
            errorsList.add(msg);
        }
    }
    private static void assertValue(Date expected, Date actual, String message) {
        if (expected != actual) {
            String msg = 'VALIDATION: ' + message + ' ' + expected + ', but actual is ' + actual;
            System.debug(msg);
            errorsList.add(msg);
        }
    }
    public class ValidationException extends Exception {}

// ========================================================================================================
// PRIVATE METHODS TO CREATE THE TESTING DATA
// ========================================================================================================

    private static void createAccountsAndContacts() {
        npo02__Households_Settings__c hhSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();
        hhSettings.npo02__Advanced_Household_Naming__c = false;
        update hhSettings;

        Account hh1 =  new Account(
            Name = 'CRLP TEST HOUSEHOLD 1',
            Site = TEST_SITE_NAME,
            RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Household Account')
        );
        Account hh2 =  new Account(
            Name = 'CRLP TEST HOUSEHOLD 2',
            Site = TEST_SITE_NAME,
            RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Household Account')
        );
        Account hh3 =  new Account(
            Name = 'CRLP TEST HOUSEHOLD 3',
            Site = TEST_SITE_NAME,
            RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Household Account')
        );

        Account rdAcct =  new Account(
            Name = ACCOUNT_NAME_RD,
            Site = TEST_SITE_NAME,
            RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Household Account')
        );

        Account orgAcct =  new Account(
            Name = ACCOUNT_NAME_ORG,
            Site = TEST_SITE_NAME,
            RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Organization')
        );

        Account ascAcct =  new Account(
            Name = ACCOUNT_NAME_ASC,
            Site = TEST_SITE_NAME,
            RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.SObjectType, 'Organization')
        );

        insert new List<Account>{ hh1, hh2, hh3, rdAcct, orgAcct, ascAcct };
        accounts = [SELECT Id, Name FROM Account WHERE Site = :TEST_SITE_NAME AND npe01__SYSTEMIsIndividual__c = true];

        // Two Contacts on Household 1
        Contact hh1Con1 = new Contact(
            FirstName = 'CRLPTEST-1',
            LastName = 'Household-1',
            AccountId = hh1.Id
        );
        Contact hh1Con2 = new Contact(
            FirstName = 'CRLPTEST-2',
            LastName = 'Household-1',
            AccountId = hh1.Id
        );

        // Three Contacts on Household 2
        Contact hh2Con1 = new Contact(
            FirstName = 'CRLPTEST-1',
            LastName = 'Household-2',
            AccountId = hh2.Id
        );
        Contact hh2Con2 = new Contact(
            FirstName = 'CRLPTEST-2',
            LastName = 'Household-2',
            AccountId = hh2.Id
        );
        Contact hh2Con3 = new Contact(
            FirstName = ORG_CONTACT_NAME,   // This Household Contact will be the Primary Contact on an Org Donation
            LastName = 'Household-2',
            AccountId = hh2.Id
        );

        // Two Contacts on Household 3
        Contact hh3Con1 = new Contact(
            FirstName = 'CRLPTEST-1',
            LastName = 'Household-3',
            AccountId = hh3.Id
        );
        Contact hh3Con2 = new Contact(
            FirstName = 'CRLPTEST-2',
            LastName = 'Household-3',
            AccountId = hh3.Id
        );

        // One Contacts on the RD Household Accouunt
        Contact rdCon = new Contact(
            FirstName = 'CRLPTEST-1',
            LastName = 'RDHousehold',
            AccountId = rdAcct.Id
        );

        insert new List<Contact>{ hh1Con1, hh1Con2, hh2Con1, hh2Con2, hh2Con3, hh3Con1, hh3Con2, rdCon };
        contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Account.Site = :TEST_SITE_NAME];
        hh1.npe01__One2OneContact__c = hh1Con1.Id;
        hh2.npe01__One2OneContact__c = hh2Con1.Id;
        rdAcct.npe01__One2OneContact__c = rdCon.Id;
        update new List<Account>{ hh1, hh2, rdAcct };

        rdAcct.Name = ACCOUNT_NAME_RD;
        hh1.Name = 'CRLP TEST HOUSEHOLD 1';
        hh2.Name = 'CRLP TEST HOUSEHOLD 2';
        hh3.Name = 'CRLP TEST HOUSEHOLD 3';
        update new List<Account>{ hh1, hh2, hh3, rdAcct };
    }

    private static void createGAU() {
        gau = new General_Accounting_Unit__c(
            Name = GAU_NAME,
            Active__c = true
        );
        insert gau;
    }

    private class CreateDataQueueable implements System.Queueable {

        private Integer step = 0;

        public CreateDataQueueable(Integer step) {
            this.step = step;
        }

        public void execute(QueueableContext qc) {
            if (step == 0) {
                createTestingOpportunities();
                System.enqueueJob(new CreateDataQueueable(1));
            } else if (step == 1) {
                createTestingAllocationsAndAccountSoftCredits();
            }
        }

    }

    /** *****************************************************************************************
     * @description Create test Opportunity records:
     *  - 450 Closed Won Donations
     *  - 50 Closed Lost Donations
     *  - 4 Memberships
     *  - All with Allocations, Payments and OCR's
     */
    private static void createTestingOpportunities() {

        TDTM_Config_API.disableAllRollupTriggers();

        accounts = [SELECT Id, Name FROM Account WHERE Site = :TEST_SITE_NAME AND npe01__SYSTEMIsIndividual__c = true];
        contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Account.Site = :TEST_SITE_NAME];
        gau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = :GAU_NAME LIMIT 1];

        Account orgAcct = [
            SELECT Id, Name FROM Account
            WHERE npe01__SYSTEMIsIndividual__c = false
            AND Name = :ACCOUNT_NAME_ORG
            LIMIT 1
        ];
        Contact orgContactSC = [
            SELECT Id FROM Contact
            WHERE FirstName = :ORG_CONTACT_NAME
            LIMIT 1
        ];

        List<Opportunity> opps = new List<Opportunity>();
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
            for (Integer num = 0; num < OPP_COUNT_PER_ACCT; num++) {
                Opportunity opp = new Opportunity(
                    Name = 'CRLP TEST OPP ' + num,
                    AccountId = accounts[na].Id,
                    Amount = OPPORTUNITY_AMOUNT,
                    RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Opportunity.SObjectType, 'Donation'),
                    StageName = (num < CLOSED_OPP_COUNT_PER_ACCT ? closedWonStage : closedLostStage),
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

                // Limit each year to 150 opportunities
                if (countByYear.get(theYear) == MAX_OPPS_PER_YEAR && theYear != BASE_YEAR-1) {
                    nextDate = Date.newInstance(theYear+1, 1, 1);
                }
                nextDate = nextDate.addDays(2);
            }

            nextDate = MEMBERSHIP_FIRST_DATE;
            for (Integer num =0; num < MEMBERSHIP_COUNT; num++) {
                Opportunity opp = new Opportunity(
                    Name = 'Membership Test' + num,
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

        insert opps;
    }

    private static void createTestingAllocationsAndAccountSoftCredits() {
        npe03__Recurring_Donations_Settings__c rdSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
        rdSettings.EnableAutomaticNaming__c = false;
        update rdSettings;

        TDTM_Config_API.disableAllRollupTriggers();

        accounts = [SELECT Id, Name FROM Account WHERE Site = :TEST_SITE_NAME AND npe01__SYSTEMIsIndividual__c = true];
        contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Account.Site = :TEST_SITE_NAME];
        gau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = :GAU_NAME LIMIT 1];

        UTIL_Query queryOpps = new UTIL_Query()
            .withFrom(Opportunity.SObjectType)
            .withSelectFields(new Set<String>{
                'Id', 'AccountId', 'Amount', 'CloseDate', 'RecordTypeId', 'StageName'
            })
            .withWhere('Account.Site = :TEST_SITE_NAME');
        if (UserInfo.isMultiCurrencyOrganization()) {
            queryOpps.withSelectFields(new Set<String>{ 'CurrencyIsoCode' });
        }
        List<Opportunity> opps = Database.query(queryOpps.build());

        Account orgAcct = [
            SELECT Id, Name FROM Account
            WHERE npe01__SYSTEMIsIndividual__c = false
            AND Name = :ACCOUNT_NAME_ORG
            LIMIT 1
        ];
        Contact orgContactSC = [
            SELECT Id FROM Contact
            WHERE FirstName = :ORG_CONTACT_NAME
            LIMIT 1
        ];

        // Change the OCR Role on the org donation so that it will roll up as a soft credit.
        OpportunityContactRole orgOCR = [
            SELECT Id, Role FROM OpportunityContactRole
            WHERE Opportunity.AccountId = :orgAcct.Id
            AND IsPrimary = True LIMIT 1];
        orgOCR.Role = 'Soft Credit';    // force to this because it's a good common value that should be in the filters
        update orgOCR;

        List<Allocation__c> allocs = new List<Allocation__c>();
        List<Account_Soft_Credit__c> accSCs = new List<Account_Soft_Credit__c>();

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
                && opp.StageName == closedWonStage
                ) {
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
            npe03__Installment_Period__c = RD_Constants.INSTALLMENT_PERIOD_MONTHLY,
            npe03__Date_Established__c = Date.Today().addMonths(-12),
            npe03__Schedule_Type__c = RD_Constants.SCHEDULE_TYPE_MULTIPLY_BY,
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


    /**
     * @description Used to test Rollup Performance and Grouping Size for each individual rollup type.
     * This testing uses the ExecuteRollups api to avoid SOQL and DML from impacting the performance
     * because those are notoriously unreliable. It should be noted that there is a single query in the
     * executeRollups() api to retrieve the parent record using the passed Id. It's minor, but
     * because SOQL performance varies so widely it should be considered when it comes to testing.
     *
     * Notes:
     * - Test Data created by this class must exist in the org first
     * - The "Apex" Debug Levels must be changed to "Debug" instead of "Finest" to avoid a CPU Timeout
     * - This expects to only test out of the box rollups because the query of fields across the Opportunity
     *   and related objects is hardcoded in this method.
     * - Execute this test at least 5 times to get an average of performance times.
     * @param CRLP_RollupProcessingOptions.RollupType enum
     */
    public static void testRollupPerformance(CRLP_RollupProcessingOptions.RollupType rt) {
        System.Callable npspApi = new callable_Api();

        Map<String, Object> params = new Map<String, Object>{
            'RollupType' => rt.name()
        };

        String rollupDefs = (String)npspApi.call('CRLP.GetDefinitionsForRollupType', params);
        List<CRLP_Rollup> rollups = (List<CRLP_Rollup>)JSON.deserialize(rollupDefs,
            List<CRLP_Rollup>.class);
        System.debug('=============================================');
        System.debug('- RollupType=' + params.get('RollupType'));
        System.debug('- CRLP_Rollup Size=' + rollups.size());
        System.debug('- Serialized Size=' + rollupDefs.length());

        // Select an Account or Contact
        Account acctHC = [SELECT Id, npe01__One2OneContact__c FROM Account WHERE Name = 'CRLP TEST HOUSEHOLD 1' LIMIT 1];
        Contact conHC = [SELECT Id FROM Contact WHERE Id = :acctHC.npe01__One2OneContact__c LIMIT 1];
        Contact conSC = [SELECT Id FROM Contact WHERE AccountId = :acctHC.Id AND Id != :conHC.Id LIMIT 1];
        General_Accounting_Unit__c gau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = 'CRLP Default GAU' LIMIT 1];

        // Retrieve all Opps for the specified Account
        List<Opportunity> opps = [SELECT Id, AccountId, Primary_Contact__c,
            Amount, CloseDate, IsWon, RecordTypeId, RecordType.DeveloperName,
            npe01__Member_Level__c, npe01__Membership_Origin__c,
            npe01__Membership_End_Date__c, npe01__Membership_Start_Date__c,
        (SELECT Id, ContactId, Contact.AccountId, Role FROM OpportunityContactRoles),
        (SELECT Id, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Written_Off__c, npe01__Payment_Date__c FROM npe01__OppPayment__r),
        (SELECT Id, Contact__c, Role_Name__c, Contact_Role_ID__c, Opportunity__c, Amount__c FROM Partial_Soft_Credits__r),
        (SELECT Id, Opportunity__c, Amount__c, General_Accounting_Unit__c FROM Allocations__r)
        FROM Opportunity
        WHERE AccountId = :acctHC.Id];

        Map<Id, Map<SObjectType, List<SObject>>> rollupData = new Map<Id, Map<SObjectType, List<SObject>>>();
        for (Opportunity opp : opps) {
            Map<SObjectType, List<SObject>> data = new Map<SObjectType, List<SObject>>();
            data.put(Opportunity.SObjectType, new List<SObject>{ opp });
            data.put(npe01__OppPayment__c.SObjectType, opp.npe01__OppPayment__r);
            data.put(OpportunityContactRole.SObjectType, opp.OpportunityContactRoles);
            data.put(Partial_Soft_Credit__c.SObjectType, opp.Partial_Soft_Credits__r);
            data.put(Allocation__c.SObjectType, opp.Allocations__r);
            rollupData.put(opp.Id, data);
        }

        Id parentId = acctHC.Id;
        switch on rt {
            when ContactHardCredit {
                parentId = conHC.Id;
            }
            when ContactSoftCredit {
                parentId = conSC.Id;
            }
            when GAU {
                parentId = gau.Id;
            }
        }

        Long startTime = System.currentTimeMillis();
        for (Integer n = 0; n < 5; n++) {
            CRLP_ApiExecuteRollups rollupApiProcess = new CRLP_ApiExecuteRollups()
                .withRollupType(rt)
                .withParentId(parentId)
                .withRollupData(rollupData)
                .withRollupDefs(rollups)
                .withCommitToDatabase(false);
            rollupApiProcess.executeRollups();
        }
        Long endTime = System.currentTimeMillis();
        System.debug('- Number of Opps Passed: ' + opps.size());
        System.debug('- Elapsed Time: ' + (endTime - startTime));
    }
}
