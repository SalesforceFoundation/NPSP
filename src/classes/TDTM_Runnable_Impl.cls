/*
    Copyright (c) 2013, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
 * This class performs a small database change to check the TDTM design, just
 * to showcase a sample implementation of a class that extends TDTM_Runnable.
 */
@isTest
public with sharing class TDTM_Runnable_Impl extends TDTM_Runnable {

    private static Boolean alreadyCalled = false;
    
    public override DmlWrapper run(List<Sobject> newlist, List<Sobject> oldlist, 
    TDTM_TriggerActionHelper.Action ta, Schema.DescribeSObjectResult describeSObjectResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();
        if(!alreadyCalled) {
        	alreadyCalled = true;
	        for(Integer i = 0; i < newlist.size(); i++) {
	        	dmlWrapper.objectsToInsert.add(new Contact(FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS + i,
	                                                        LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + i));
	        }
        }
        return dmlWrapper;
    }
}