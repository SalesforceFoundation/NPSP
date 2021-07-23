/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description API class that exposes CAO (Contacts and Organizations) Constants and helper methods.
*/
global class CAO_Constants_API {

    /*******************************************************************************************************
    * @description One-to-One value for system processor field
    */ 
    global static String ONE_TO_ONE_PROCESSOR {
        get {return CAO_Constants.ONE_TO_ONE_PROCESSOR;}
        private set;
    }

    /*******************************************************************************************************
    * @description One-to-One org type value
    */ 
    global static String ONE_TO_ONE_ORGANIZATION_TYPE {
        get {return CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;}
        private set;
    }

    /*******************************************************************************************************
    * @description Individual Bucket value for system processor field
    */ 
    global static String BUCKET_PROCESSOR {
        get {return CAO_Constants.BUCKET_PROCESSOR;}
        private set;
    }

    /*******************************************************************************************************
    * @description Individual Bucket org type value
    */ 
    global static String BUCKET_ORGANIZATION_TYPE {
        get {return CAO_Constants.BUCKET_ORGANIZATION_TYPE;}
        private set;
    }

    /*******************************************************************************************************
    * @description Individual Bucket Account name
    */ 
    global static String BUCKET_ACCOUNT_NAME {
        get {return CAO_Constants.BUCKET_ACCOUNT_NAME;}
        private set;
    }

    /*******************************************************************************************************
    * @description Household Account value for system processor field
    */ 
    global static String HH_ACCOUNT_PROCESSOR {
        get {return CAO_Constants.HH_ACCOUNT_PROCESSOR;}
        private set;
    }

    /*******************************************************************************************************
    * @description Household Account org type value
    */ 
    global static String HH_ACCOUNT_TYPE {
        get {return CAO_Constants.HH_ACCOUNT_TYPE;}
        private set;
    }

    /*******************************************************************************************************
    * @description Household Account value for the standard Type field
    */ 
    global static string HH_TYPE {
        get {return CAO_Constants.HH_TYPE;}
        private set;
    }

}