@IsTest
public class ListDonation_TEST {
	@IsTest
	public static void testGetDonationHistory() {
		Test.startTest();
		
		Date myDateTime = Date.newInstance(2020, 2, 2);

		Account mockDefaultAccount = new Account(Name = 'Default Account');
		insert mockDefaultAccount;

		Contact mockDefaultContact = new Contact(
			FirstName='Alice', 
			LastName='Patterson', 
			AccountId=mockDefaultAccount.Id
		);
		Contact secondaryContact = new Contact(
			FirstName='Josh', 
			LastName='Patterson',
			AccountId=mockDefaultAccount.Id
		);
		insert mockDefaultContact;
		insert secondaryContact;

		Opportunity opportunityHardCredit = new Opportunity(
			Name='HardCredit1', 
			AccountId=mockDefaultAccount.Id, 
			Primary_Contact__c=mockDefaultContact.Id, 
			Amount=400, 
			StageName='Closed Won', 
			CloseDate=myDateTime
		);
		Opportunity opportunitySoftCredit = new Opportunity(
			Name='SoftCredit1', 
			AccountId=mockDefaultAccount.Id, 
			Primary_Contact__c=secondaryContact.Id, 
			Amount=200, 
			StageName='Closed Won', 
			CloseDate=myDateTime
		);
		Opportunity opportunityPartialSoftCredit = new Opportunity(
			Name='PartialSoftCredit1', 
			AccountId=mockDefaultAccount.Id, 
			Primary_Contact__c=secondaryContact.Id, 
			Amount=150, 
			StageName='Closed Won', 
			CloseDate=myDateTime
		);
		insert opportunityHardCredit;
		insert opportunitySoftCredit;
		insert opportunityPartialSoftCredit;

		OpportunityContactRole oppCntRoleSoftCredit = new OpportunityContactRole(
			Role='Soft Credit', 
			OpportunityId=opportunitySoftCredit.Id, 
			ContactId=mockDefaultContact.Id, 
			isPrimary=false
		);
		OpportunityContactRole oppCntRolePartialSoftCredit = new OpportunityContactRole(
			Role='Soft Credit', 
			OpportunityId=opportunityPartialSoftCredit.Id, 
			ContactId=mockDefaultContact.Id, 
			isPrimary=false
		);
		insert oppCntRoleSoftCredit;
		insert oppCntRolePartialSoftCredit;

		Partial_Soft_Credit__c partialSoftCredit = new Partial_Soft_Credit__c (
			Amount__c=50,
			Contact__c=mockDefaultContact.Id,
			Opportunity__c=opportunityPartialSoftCredit.Id,
			Contact_Role_ID__c=oppCntRolePartialSoftCredit.Id
		);
		insert partialSoftCredit;

		Test.stopTest();
		
		List<ListDonation.DonationHistory> donationHistory = ListDonation.getDonationHistory(mockDefaultContact.Id, 0);
		List<ListDonation.DonationHistory> filteredDonationHistory = new List<ListDonation.DonationHistory>();

		for (ListDonation.DonationHistory donation : donationHistory) {
			filteredDonationHistory.add(donation);
		}
		System.assertEquals(3, donationHistory.size());
	}
}