/*
    Copyright (c) 2020, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2021
* @group BDI
* @description Test class for testing BDI Matching Donation Logic
*/
@IsTest
private class BDI_MatchDonations_TEST {

   @IsTest
   static void shouldPopulateDonationMatchingContactQueryIds() {
      BDI_MatchDonations.perfLog = new BDI_PerfLogger.PerfLog();
      BDI_MatchDonations bdiMatchDonations = new BDI_MatchDonations();
      bdiMatchDonations.bdi = stubFor(new BDI_DataImportServiceMock()
          .withNullContactId(false));

      bdiMatchDonations.getPotentialDonationMatches(
          new List<DataImport__c>{
              new DataImport__c(Donation_Donor__c = 'Contact1', DonationImported__c = null)
          });
      System.assert(!bdiMatchDonations.setConId.isEmpty());
   }

   @IsTest
   static void shouldNotPopulateDonationMatchingContactQueryIds() {
      BDI_MatchDonations bdiMatchDonations = new BDI_MatchDonations();
      bdiMatchDonations.bdi = stubFor(new BDI_DataImportServiceMock()
          .withNullContactId(true).withNullAccountId(true));
      bdiMatchDonations.getPotentialDonationMatches(
          new List<DataImport__c>{
              new DataImport__c(Donation_Donor__c = 'Contact1', DonationImported__c = null)
          });
      System.assert(bdiMatchDonations.setConId.isEmpty());
   }

   @IsTest
   static void shouldPopulateDonationMatchingAccountQueryIds() {
      BDI_MatchDonations.perfLog = new BDI_PerfLogger.PerfLog();
      BDI_MatchDonations bdiMatchDonations = new BDI_MatchDonations();
      bdiMatchDonations.bdi = stubFor(new BDI_DataImportServiceMock()
          .withNullAccountId(false));

      bdiMatchDonations.getPotentialDonationMatches(
          new List<DataImport__c>{
              new DataImport__c(Donation_Donor__c = 'Account1', DonationImported__c = null)
          });
      System.assert(!bdiMatchDonations.setAccId.isEmpty());
   }

   @IsTest
   static void shouldNotPopulateDonationMatchingAccountQueryIds() {
      BDI_MatchDonations bdiMatchDonations = new BDI_MatchDonations();
      bdiMatchDonations.bdi = stubFor(new BDI_DataImportServiceMock()
          .withNullAccountId(true));
      bdiMatchDonations.getPotentialDonationMatches(
          new List<DataImport__c>{
              new DataImport__c(Donation_Donor__c = 'Account1', DonationImported__c = null)
          });
      System.assert(bdiMatchDonations.setAccId.isEmpty());
   }

   @IsTest
   static void shouldPopulateDonationMatchingOpportunityQueryIds() {
      BDI_MatchDonations.perfLog = new BDI_PerfLogger.PerfLog();
      BDI_MatchDonations bdiMatchDonations = new BDI_MatchDonations();
      bdiMatchDonations.bdi = stubFor(new BDI_DataImportServiceMock()
          .withNullAccountId(true));
      bdiMatchDonations.getPotentialDonationMatches(
          new List<DataImport__c>{
              new DataImport__c(Donation_Donor__c = 'Account1',
                  DonationImported__c = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType))
          });
      System.assert(!bdiMatchDonations.setOppId.isEmpty());
   }

   private class BDI_DataImportServiceMock implements StubProvider {
      private Boolean withNullContactId;
      private Boolean withNullAccountId;

      private BDI_DataImportServiceMock withNullContactId(Boolean withNullContactId) {
         this.withNullContactId = withNullContactId;
         return this;
      }

      private BDI_DataImportServiceMock withNullAccountId(Boolean withNullAccountId) {
         this.withNullAccountId = withNullAccountId;
         return this;
      }

      private Account buildAccountFromDI() {
         if(withNullAccountId) {
            return new Account(Id = null);
         }
         return new Account(Id = UTIL_UnitTestData_TEST.mockId(Account.SObjectType));
      }

      private Contact buildContactFromDI() {
         if(withNullContactId) {
            return new Contact(Id = null);
         }
         return new Contact(Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType));
      }

      public Object handleMethodCall(
          Object stubbedObject,
          String stubbedMethodName,
          Type returnType,
          List<Type> listOfParamTypes,
          List<String> listOfParamNames,
          List<Object> listOfArgs) {

         switch on (stubbedMethodName) {
            when 'mapDataImportFields' {
               return new Map<String, String>{};
            }
            when 'contactFromDi' {
               return buildContactFromDI();
            }
            when 'AccountFromDi'{
               return buildAccountFromDI();
            }
         }
         return null;
      }
   }

   private static BDI_DataImportService stubFor(BDI_DataImportServiceMock bdiDataImportServiceMock) {
      return (BDI_DataImportService) Test.createStub(
          BDI_DataImportService.class, bdiDataImportServiceMock);
   }

}