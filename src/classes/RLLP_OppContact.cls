public with sharing class RLLP_OppContact extends RLLP_Definition {
//method to take a list of Opportunities
//method to take a list of Accounts

//what class do I choose to do the querying of existing records to see if I update them or not?

    public RLLP_OppContact() {
        summaryObject = Contact.SObjectType;
        detailObject = Opportunity.SObjectType;
        attributionObject = OpportunityContactRole.SObjectType;
        attributionField = OpportunityContactRole.ContactId;
        closeDateField = Opportunity.CloseDate;
        amountField = Opportunity.Amount;
        
        Integer thisYear = RLLP_FiscalYears.getYear(System.today());

        RLLP_Wrapper standardRollup = new RLLP_Wrapper(this);
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__FirstCloseDate__c, RLLP_Operation.RollupType.FIRST, Opportunity.CloseDate));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__LastCloseDate__c, RLLP_Operation.RollupType.LAST, Opportunity.CloseDate));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__SmallestAmount__c, RLLP_Operation.RollupType.SMALLEST, Opportunity.Amount));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__LargestAmount__c, RLLP_Operation.RollupType.LARGEST, Opportunity.Amount));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__LastOppAmount__c, RLLP_Operation.RollupType.LAST, Opportunity.Amount));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__AverageAmount__c, RLLP_Operation.RollupType.AVERAGE));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__TotalOppAmount__c, RLLP_Operation.RollupType.SUM));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__NumberOfClosedOpps__c, RLLP_Operation.RollupType.COUNT));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__OppAmount2YearsAgo__c, RLLP_Operation.RollupType.SUM, String.valueOf(thisYear-2)));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__OppAmountLastYear__c, RLLP_Operation.RollupType.SUM, String.valueOf(thisYear-1)));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__OppAmountThisYear__c, RLLP_Operation.RollupType.SUM, String.valueOf(thisYear)));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__OppsClosed2YearsAgo__c, RLLP_Operation.RollupType.COUNT, String.valueOf(thisYear-2)));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__OppsClosedLastYear__c, RLLP_Operation.RollupType.COUNT, String.valueOf(thisYear-1)));
        standardRollup.operations.add(new RLLP_Operation(Contact.npo02__OppsClosedThisYear__c, RLLP_Operation.RollupType.COUNT, String.valueOf(thisYear)));

        standardRollup.exclusions.put(Opportunity.SObjectType, new List<RLLP_Exclusion>());
        standardRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.RecordTypeId, RLLP_Exclusion.Operator.IS_NOT_INCLUDED, UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Excluded_Account_Opp_Rectypes__c));
        standardRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.Type, RLLP_Exclusion.Operator.IS_NOT_INCLUDED, UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Excluded_Account_Opp_Types__c));
        standardRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.IsClosed, RLLP_Exclusion.Operator.EQUALS, 'false'));
        standardRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.IsWon, RLLP_Exclusion.Operator.EQUALS, 'false'));

        standardRollup.exclusions.put(OpportunityContactRole.SObjectType, new List<RLLP_Exclusion>());
        standardRollup.exclusions.get(OpportunityContactRole.SObjectType).add(new RLLP_Exclusion(OpportunityContactRole.SObjectType, OpportunityContactRole.IsPrimary, RLLP_Exclusion.Operator.EQUALS, 'false'));

        wrappers.add(standardRollup);

        RLLP_Wrapper membershipRollup = new RLLP_Wrapper(this);
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__LastMembershipAmount__c, RLLP_Operation.RollupType.LAST, Opportunity.Amount));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__LastMembershipDate__c, RLLP_Operation.RollupType.LAST, Opportunity.CloseDate));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__LastMembershipLevel__c, RLLP_Operation.RollupType.LAST, Opportunity.npe01__Member_Level__c));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__LastMembershipOrigin__c, RLLP_Operation.RollupType.LAST, Opportunity.npe01__Membership_Origin__c));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__MembershipJoinDate__c, RLLP_Operation.RollupType.FIRST, Opportunity.CloseDate));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__MembershipEndDate__c, RLLP_Operation.RollupType.LAST, Opportunity.CloseDate));//TODO this isn't quite right, needs offset
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__NumberOfMembershipOpps__c, RLLP_Operation.RollupType.COUNT));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__TotalMembershipOppAmount__c, RLLP_Operation.RollupType.SUM));

        membershipRollup.exclusions.put(Opportunity.SObjectType, new List<RLLP_Exclusion>());
        membershipRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.RecordTypeId, RLLP_Exclusion.Operator.IS_NOT_INCLUDED, UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Excluded_Account_Opp_Rectypes__c));
        membershipRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.Type, RLLP_Exclusion.Operator.IS_NOT_INCLUDED, UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Excluded_Account_Opp_Types__c));
        membershipRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.IsClosed, RLLP_Exclusion.Operator.EQUALS, 'false'));
        membershipRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.IsWon, RLLP_Exclusion.Operator.EQUALS, 'false'));

        membershipRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.RecordTypeId, RLLP_Exclusion.Operator.NOT_EQUALS, UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Membership_Record_Types__c));

        wrappers.add(membershipRollup);

        RLLP_Wrapper nDaysRollup = new RLLP_Wrapper(this);
        nDaysRollup.operations.add(new RLLP_Operation(Contact.npo02__OppAmountLastNDays__c, RLLP_Operation.RollupType.SUM));
        nDaysRollup.operations.add(new RLLP_Operation(Contact.npo02__OppsClosedLastNDays__c, RLLP_Operation.RollupType.COUNT));

        nDaysRollup.exclusions.put(Opportunity.SObjectType, new List<RLLP_Exclusion>());
        nDaysRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.RecordTypeId, RLLP_Exclusion.Operator.IS_NOT_INCLUDED, UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Excluded_Account_Opp_Rectypes__c));
        nDaysRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.Type, RLLP_Exclusion.Operator.IS_NOT_INCLUDED, UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Excluded_Account_Opp_Types__c));
        nDaysRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.IsClosed, RLLP_Exclusion.Operator.EQUALS, 'false'));
        nDaysRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.IsWon, RLLP_Exclusion.Operator.EQUALS, 'false'));

        nDaysRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.CloseDate, RLLP_Exclusion.Operator.LESS, '-' + UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Rollup_N_Day_Value__c));
        nDaysRollup.exclusions.get(Opportunity.SObjectType).add(new RLLP_Exclusion(Opportunity.SObjectType, Opportunity.CloseDate, RLLP_Exclusion.Operator.GREATER, '0'));

        wrappers.add(nDaysRollup);

    }
}