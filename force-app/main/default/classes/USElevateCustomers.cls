/**
 * Created by voduyemi on 8/5/21.
 */

public with sharing class USElevateCustomers implements IAudience{

   private static final String US_ISO_CODE = 'US';

   public Set<String> audience() {
      Set<String> audience = new Set<String>();
      if (isTargetOrganization()) {
         for (User user: userSelector.getUsers()) {
            audience.add(new UserId(user.Id).stringValue());
         }
      }
      return audience;
   }

   public Boolean isTargetOrganization() {
      return !isElevateCustomer() && isUSOrganization();
   }

   private Boolean isElevateCustomer () {
      PS_IntegrationServiceConfig serviceConfig = new PS_IntegrationServiceConfig();
      return serviceConfig.isIntegrationEnabled();
   }

   private Boolean isUSOrganization () {
      return [
          SELECT SignupCountryIsoCode
          FROM Organization
      ].SignupCountryIsoCode == US_ISO_CODE;
   }

   @TestVisible
   private UserSelector userSelector {
      get {
         if (userSelector == null) {
            userSelector = new UserSelector();
         }
         return userSelector;
      }
      set;
   }
}