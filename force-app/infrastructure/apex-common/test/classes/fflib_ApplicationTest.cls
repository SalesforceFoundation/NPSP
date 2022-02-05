/**
 * Copyright (c), FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

@IsTest
private class fflib_ApplicationTest 
{
	@IsTest
	private static void callingUnitOfWorkFactoryShouldGivenStandardImplsAndMockImpls()
	{
		// Standard behaviour
		System.assert(UnitOfWork.newInstance() instanceof fflib_SObjectUnitOfWork);
 		
		// Mocking behaviour
		UnitOfWork.setMock(new fflib_SObjectMocks.SObjectUnitOfWork(new fflib_ApexMocks()));
		System.assert(UnitOfWork.newInstance() instanceof fflib_SObjectMocks.SObjectUnitOfWork);
	}

	@IsTest
	private static void callingUnitOfWorkFactoryWithCustomTypesShouldGivenStandardImplsAndMockImpls()
	{
		// Standard behaviour
		System.assert(
				UnitOfWork.newInstance(
						new List<SObjectType>{ Account.SObjectType}
				) instanceof fflib_SObjectUnitOfWork);

		// Mocking behaviour
		UnitOfWork.setMock(new fflib_SObjectMocks.SObjectUnitOfWork(new fflib_ApexMocks()));
		System.assert(
				UnitOfWork.newInstance(
						new List<SObjectType>{ Account.SObjectType}
				) instanceof fflib_SObjectMocks.SObjectUnitOfWork);
	}

	@IsTest
	private static void callingUnitOfWorkWithCustomDML()
	{
		// Given a custom DML class and a new record
		CustomDML customDML = new CustomDML();
		Account myAccount = new Account(Name = 'Test Account');

		// When the unit of work is instantiated from the Application Class and the record is registered and commited
		fflib_ISObjectUnitOfWork unitOfWork = UnitOfWork.newInstance(customDML);
		unitOfWork.registerNew(myAccount);
		unitOfWork.commitWork();

		// Then the Custom DML is used by the unit of Work
		System.assert(customDML.isInsertCalled, 'Oops, custom DML was not called');
	}

	@IsTest
	private static void callingMockedUnitOfWorkWithCustomDML()
	{
		// Given a custom DML class and a new record
		CustomDML customDML = new CustomDML();
		Account myAccount = new Account(Name = 'Test Account');

		// When the unit of work is instantiated from the Application Class and the record is registered and commited
		UnitOfWork.setMock(new fflib_SObjectMocks.SObjectUnitOfWork(new fflib_ApexMocks()));
		fflib_ISObjectUnitOfWork uow = UnitOfWork.newInstance(customDML);

		uow.registerNew(myAccount);
		uow.commitWork();

		// Then the Custom DML should not be used by the unit of Work
		System.assert(!customDML.isInsertCalled, 'Oops, custom DML was called');
	}

	@IsTest
	private static void callingUnitOfWorkWithCustomObjectTypesAndDML()
	{
		// Given a custom DML class and a new record
		CustomDML customDML = new CustomDML();
		Account myAccount = new Account(Name = 'Test Account');

		// When the unit of work is instantiated from the Application Class and the record is registered and commited
		fflib_ISObjectUnitOfWork unitOfWork = UnitOfWork.newInstance(
				new List<SObjectType>{ Account.SObjectType },
				customDML
		);
		unitOfWork.registerNew(myAccount);
		unitOfWork.commitWork();

		// Then the Custom DML is used by the unit of Work
		System.assert(customDML.isInsertCalled, 'Oops, custom DML was not called');
	}

	@IsTest
	private static void callingMockedUnitOfWorkWithCustomObjectTypesAndDML()
	{
		// Given a custom DML class and a new record
		CustomDML customDML = new CustomDML();
		Account myAccount = new Account(Name = 'Test Account');

		// When the unit of work is instantiated from the Application Class and the record is registered and commited
		UnitOfWork.setMock(new fflib_SObjectMocks.SObjectUnitOfWork(new fflib_ApexMocks()));
		fflib_ISObjectUnitOfWork uow = UnitOfWork.newInstance(
				new List<SObjectType>{ Account.SObjectType },
				customDML
		);
		uow.registerNew(myAccount);
		uow.commitWork();

		// Then the Custom DML should not be used by the unit of Work
		System.assert(!customDML.isInsertCalled, 'Oops, custom DML was called');
	}

	public class CustomDML implements fflib_SObjectUnitOfWork.IDML
	{
		public boolean isInsertCalled = false;
		public boolean isUpdateCalled = false;
		public boolean isDeleteCalled = false;
		public boolean isPublishCalled = false;
		public Boolean isEmptyRecycleBinCalled = false;

		public void dmlInsert(List<SObject> objList){
			this.isInsertCalled = true;
		}
		public void dmlUpdate(List<SObject> objList){
			this.isUpdateCalled = true;
		}
		public void dmlDelete(List<SObject> objList){
			this.isDeleteCalled = true;
		}
		public void eventPublish(List<SObject> objList)
		{
			this.isPublishCalled = true;
		}
		public void emptyRecycleBin(List<SObject> objList)
		{
			this.isEmptyRecycleBinCalled = true;
		}
	}

	// Configure and create the UnitOfWorkFactory for this Application
	public static final fflib_Application.UnitOfWorkFactory UnitOfWork = 
		new fflib_Application.UnitOfWorkFactory(
				new List<SObjectType> { 
					Account.SObjectType,
					Opportunity.SObjectType,
					OpportunityLineItem.SObjectType });	

}
