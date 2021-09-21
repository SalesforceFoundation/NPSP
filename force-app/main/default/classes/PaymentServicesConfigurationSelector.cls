/**
 * Created by voduyemi on 9/21/21.
 */

public with sharing class PaymentServicesConfigurationSelector {

   public List<Payment_Services_Configuration__c> getConfigRecordsByName(List<String> serviceNames) {
      return [
          SELECT Key__c, Value__c, Service__c
          FROM Payment_Services_Configuration__c
          WHERE Service__c IN :serviceNames
      ];
   }

   public List<Payment_Services_Configuration__c> getLastModifiedConfigRecord() {
      return [
          SELECT Key__c, Value__c, Service__c,
              LastModifiedById, LastModifiedDate
          FROM Payment_Services_Configuration__c
          ORDER BY LastModifiedDate DESC
          LIMIT 1
      ];
   }

}