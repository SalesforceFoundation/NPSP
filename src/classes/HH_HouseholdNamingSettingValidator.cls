public with sharing class HH_HouseholdNamingSettingValidator {
	public HH_HouseholdNamingSettingValidator() {
	}

	public Notification validate(Household_Naming_Settings__c settings) {
		Notification notification = new Notification();

		validateImplementingClass(notification);
		validateFormat(notification);

		return notification;
	}

	@TestVisible
	private void validateImplementingClass(Notification notification) {

	}

	@TestVisible
	private void validateFormat(Notification notification) {
		validateFormat('Household_Name_Format__c', notification);
		validateFormat('Formal_Greeting_Format__c', notification);
		validateFormat('Informal_Greeting_Format__c', notification);

		validateContactFieldsApiName(notification);
	}

	private void validateFormat(String fieldName, Notification notification) {

	}

	private void validateContactFieldsApiName(Notification notification) {

	}

	public class Notification {
		private String[] errors = new String[0];
		
		public Notification addErrors(String[] errors) {
			if (errors != null) {
				this.errors.addAll(errors);
			}

			return this;
		}

		public Notification addError(String error) {
			if (!String.isBlank(error)) {
				errors.add(error);
			}

			return this;
		}

		public String[] getErrors() {
			return errors;
		}

		public Boolean isSuccess() {
			return errors.isEmpty();
		}
	}
}