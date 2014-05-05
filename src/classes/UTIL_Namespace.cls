/*
    Copyright (c) 2014 Salesforce.com Foundation
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
* @author Salesforce.com Foundation
* @date 2014 
* @description Class which holds static methods for common utilities, 
* such as detecting whether we are in a managed package, and some string helpers.
*/

public without sharing class UTIL_Namespace { 
    
    /******************************************************************************************************
    * @description boolean property which tracks whether we are running in our managed packaged, or unmanaged code.
    *******************************************************************************************************/    
    private static boolean fCheckedForManagedPackage = false;
    public static boolean InManagedPackage {
        get {
            if (!fCheckedForManagedPackage) {
                // first try to look up an object using pkg namespace - this should only work in an installed (i.e. client) instance
                Schema.SObjectType token = Schema.getGlobalDescribe().get('npsp__Trigger_Handler__c');
                if (token != null) {                
                    InManagedPackage = true;
                    fCheckedForManagedPackage = true;
                } else {
                    // if this doesn't work, we are either in the package instance itself, or in an unmanaged developer instance (git clone)
                    // the former still needs to include the prefixes, while the latter needs to not include them
                    // in order to tell the difference, try a dynamic query w/ the prefix and see if we get an err
                    string soql = 'SELECT Id FROM npsp__Trigger_Handler__c LIMIT 1';
                    try {
                        SObject[] recs = database.query(soql); 
                    } catch (exception e) {
                        string msg = e.getMessage();
                        if (msg.contains('sObject type') && msg.contains('is not supported')) {
                            InManagedPackage = false;
                            fCheckedForManagedPackage = true;
                        }
                    } finally {
                        if (!fCheckedForManagedPackage) {
                            InManagedPackage = true;
                            fCheckedForManagedPackage = true;
                        }
                    }
                }               
            }
            return InManagedPackage;            
        }
        set;
    }
    
    
    /*******************************************************************************************************
    * @description Static method that takes a string
    * If we are in a managed package, tokens in dynamic SOQL must include the package namespace prefix.
    * If you ever deploy this package as unmanaged, this routine will do nothing!
    * @param str token name 
    * @return token name, with namespace prefix, if required.
    ********************************************************************************************************/
    public static string StrTokenNSPrefix(string str) {
        if (!InManagedPackage) return str;
        str = 'npsp__' + str;
        return str;
    }
    
    /*******************************************************************************************************
    * @description Static method that takes a string
    * If we are in a managed package, tokens in dynamic SOQL must include the package namespace prefix.
    * BUT it turns out that Describe Field Tokens do NOT namespace prefix fields within the package.
    * so this helper can be used in our describe code to remove an incorrect namespace prefix.
    * @param str token name 
    * @return token name, with namespace prefix removed, if present.
    ********************************************************************************************************/
    public static string StrTokenRemoveNSPrefix(string str) {
        return str.replace('npsp__', '');
    }
      
    // If we ever need to only namespace strings ending in __c, the method below should work
    /*
    public static string StrTokenNSPrefixOnlyCustom(string str) {
        if (str.endsWith('__c') || str.ends) {
            return StrTokenNSPrefix(str);
        }
    }
    */
    
    /*******************************************************************************************************
    * @description Static method that takes a string of a multiple potential field names or object names.  
    * If it is a custom object or field (name ends with __c), it prepends the namespace prefix if required.
    * If we are in a managed package, tokens in dynamic SOQL must include the package namespace prefix.
    * If you ever deploy this package as unmanaged, this routine will do nothing!
    * @param str string that contains 0 or more token names 
    * @return same string with token names, namespace prefixed, if required.
    ********************************************************************************************************/
    public static string StrAllNSPrefix(string str) {
        if (!InManagedPackage) return str;
        Pattern pat = Pattern.Compile('[a-zA-z0-9]*__c');
        Matcher match = pat.matcher(str);
        return match.replaceAll('npsp__$0');
    }
    
    /*******************************************************************************************************
    * @description Static method that detects if we are running in a sandbox.
    * @return true if running in sandbox. false otherwise.
    ********************************************************************************************************/
    public static Boolean isSandbox() {
	    return URL.getSalesforceBaseUrl().getHost().left(2).equalsignorecase('cs');
	}
	
	/*******************************************************************************************************
    * @description Static method that returns the real email if it's a sandbox email.
    * @return string with user's email.
    ********************************************************************************************************/
    public static String sandboxEmailToRealEmail(String email) {
        if((isSandbox() || Test.isRunningTest()) && email.contains('=')) {
          email = email.substring(0, email.indexOf('@'));
          email = email.replace('=', '@');
        }
        return email;
    }
}