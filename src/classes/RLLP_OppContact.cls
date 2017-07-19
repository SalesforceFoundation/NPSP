public with sharing class RLLP_OppContact extends RLLP_Definition {
//method to take a list of Opportunities
//method to take a list of Accounts

//what class do I choose to do the querying of existing records to see if I update them or not?

    private static Set<String> excludedOppTypes = new Set<String>();
    private static Set<Id> excludedOppRecordTypes = new Set<Id>();
    private static Integer nDays = UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Rollup_N_Day_Value__c.intValue();

    public RLLP_OppContact() {
        summaryObject = Contact.SObjectType;
        detailObject = Opportunity.SObjectType;
        attributionObject = OpportunityContactRole.SObjectType;
        attributionId = OpportunityContactRole.ContactId;
        closeDateField = Opportunity.CloseDate;
        amountField = Opportunity.Amount;
        
        //TODO move these to static util class for all the vars multiple rollup classes use
        if (!String.isBlank(UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Excluded_Account_Opp_Types__c)) {
            excludedOppTypes = new set<string>(UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Excluded_Account_Opp_Types__c.split(';'));
        }    
        if (!String.isBlank(UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Excluded_Account_Opp_Rectypes__c)) {
            excludedOppRecordTypes = new Set<Id>((List<Id>)UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Excluded_Account_Opp_Rectypes__c.split(';'));
        }

        Integer thisYear = RLLP_FiscalYears.getYear(System.today());

        RLLP_Definition.OperationWrapper standardRollup = new RLLP_Definition.OperationWrapper(new StandardOpportunityExclusion());
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
        wrappers.add(standardRollup);

        RLLP_Definition.OperationWrapper membershipRollup = new RLLP_Definition.OperationWrapper(new MembershipOpportunityExclusion());
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__LastMembershipAmount__c, RLLP_Operation.RollupType.LAST, Opportunity.Amount));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__LastMembershipDate__c, RLLP_Operation.RollupType.LAST, Opportunity.CloseDate));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__LastMembershipLevel__c, RLLP_Operation.RollupType.LAST, Opportunity.npe01__Member_Level__c));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__LastMembershipOrigin__c, RLLP_Operation.RollupType.LAST, Opportunity.npe01__Membership_Origin__c));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__MembershipJoinDate__c, RLLP_Operation.RollupType.FIRST, Opportunity.CloseDate));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__MembershipEndDate__c, RLLP_Operation.RollupType.LAST, Opportunity.CloseDate));//TODO this isn't quite right, needs offset
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__NumberOfMembershipOpps__c, RLLP_Operation.RollupType.COUNT));
        membershipRollup.operations.add(new RLLP_Operation(Contact.npo02__TotalMembershipOppAmount__c, RLLP_Operation.RollupType.SUM));
        wrappers.add(membershipRollup);

        RLLP_Definition.OperationWrapper nDaysRollup = new RLLP_Definition.OperationWrapper(new NDaysOpportunityExclusion());
        nDaysRollup.operations.add(new RLLP_Operation(Contact.npo02__OppAmountLastNDays__c, RLLP_Operation.RollupType.SUM));
        nDaysRollup.operations.add(new RLLP_Operation(Contact.npo02__OppsClosedLastNDays__c, RLLP_Operation.RollupType.COUNT));
        wrappers.add(nDaysRollup);

    }

    public virtual class StandardOpportunityExclusion implements IExclusion {
        public virtual Boolean isExcluded(SObject detail) {
            String oppType = (String)detail.get('Type');
            Id oppRecordType = (Id)detail.get('RecordTypeId');
            if (!String.isBlank(oppType) && excludedOppTypes.contains(oppType)) {
                return true;
            }
            if (excludedOppRecordTypes.contains(oppRecordType)) {
                return true;
            }
            return false;
        }
    }

    public class MembershipOpportunityExclusion extends StandardOpportunityExclusion implements IExclusion {
        public override Boolean isExcluded(SObject detail) {
            if (super.isExcluded(detail)) {
                return true;
            }
            //TODO: check membership
            return false;
        }
    }

    public class NDaysOpportunityExclusion extends StandardOpportunityExclusion implements IExclusion {
        public override Boolean isExcluded(SObject detail) {
            if (super.isExcluded(detail)) {
                return true;
            }
            Date closeDate = (Date)detail.get(Opportunity.CloseDate);
            if (closeDate > System.today() || closeDate.addDays(nDays) < System.today()) {
                return true;
            }
            return false;
        }
    }
}