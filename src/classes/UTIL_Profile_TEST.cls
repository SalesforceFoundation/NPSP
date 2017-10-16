/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
* @group Utilities
* @description Unit tests for UTIL_Profile class
*/
@isTest
private class UTIL_Profile_TEST {
	private static Integer BULK_CALL = 200;

	/**************************************************************************************************************************
    @description Test multiple calls of the method GetInstance() to make sure the UTIL_Profile instance is constructed only once.
    verify: The query (Get Profiles) should run only once.
    ***************************************************************************************************************************/   
    private static testMethod void testGetInstanceSingleton() {
    	Test.startTest();
    	//Verify there is no query at the begining of the test.
    	System.assertEquals(0, Limits.getQueries(), 'The query count should be 0 because no query has been run');

    	UTIL_Profile profileUtil = UTIL_Profile.getInstance();
    	//The GetInstance calls the UTIL_Profile Constructor which contains a query on the Profile.
    	System.assertNotEquals(null, profileUtil, 'The GetInstance should return an instance of UTIL_Profile');
    	System.assertEquals(1, Limits.getQueries(), 'The query count should be 1 because the GetInstance constructs the UTIL_Profile');

    	//Test multiple calls of the GetInstance in a Bulk context.
    	for (Integer i = 0; i < BULK_CALL; i++) {
    		profileUtil = UTIL_Profile.getInstance();
    	}
    	//The GetInstance should not call the Constructor of UTIL_Profile anymore.
    	System.assertNotEquals(null, profileUtil, 'The GetInstance should have the same instance of UTIL_Profile');
    	System.assertEquals(1, Limits.getQueries(), 'The query count should not change');
    	Test.stopTest();
    }

    /**************************************************************************************************************************
    @description Test the GetProfileIds.
    verify: The result returned by the GetProfileIds should is correct.
    ***************************************************************************************************************************/   
    private static testMethod void testGetProfileIds() {
    	//Get all the Profiles in the Org, and group by Ids
    	Map<String,List<Profile>> orgProfilesByName = getProfilesByName();

    	Test.startTest();
    	UTIL_Profile profileUtil = UTIL_Profile.getInstance();
    	Test.stopTest();

    	System.assertNotEquals(null, profileUtil, 'The GetInstance should return an instance of UTIL_Profile');

    	for (String currentProfileName : orgProfilesByName.keySet()) {
    		//Confirm that the result returned by GetProfileIds is correct.
    		System.assertEquals(
    			orgProfilesByName.get(currentProfileName).size(), 
    			profileUtil.getProfileIds(currentProfileName).size(),
    			'The number of Profiles that have the Name ' + currentProfileName + ' should be equals to the profileUtil.getProfileIds ones'
    		);
    		for (Profile currentProfile : orgProfilesByName.get(currentProfileName)) {
    			System.assert(profileUtil.getProfileIds(currentProfileName).contains(currentProfile.Id));
    		}
    	}
    }

    /*********************************************************************************************************
    * @description Get a Map of All Profiles, grouped by Name
    * @return Map of Profiles, grouped by Name
    */
	private static Map<String,List<Profile>> getProfilesByName() {
		Map<String,List<Profile>> result = new Map<String,List<Profile>>();
		List<Profile> profiles = [
    		SELECT Name
    		FROM Profile
    	];
		for (Profile currentProfile :profiles) {
			if (result.containsKey(currentProfile.Name) == false) {
				result.put(currentProfile.Name, new List<Profile>());
			}
			result.get(currentProfile.Name).add(currentProfile);
		}
		return result;
	}
}

