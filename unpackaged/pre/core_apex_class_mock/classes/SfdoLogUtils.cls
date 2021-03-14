/**
* Support Instrumentation for Salesforce.org Managed Packages
* @author M.Smith
* @date 2021-03-07
* @since 232
*
* @description: Mock class necessary ONLY when unmanaged NPSP is deployed into an org without a namespace.
* - This class MUST match the core implementation of the "SfdoLogUtils" file-based apex class. 
* - The methods in this class mock the identical exposed methods in the core version of the class, however the core class is ONLY available to
*   managed code with an official SFDO product namespace. 
* - By deploying this unmanaged class to the org BEFORE the rest of the product code is deployed, it will allow any package code that references
*   the SfdoLogUtils class to compile property by redirecting it to "this" mock class.
*
* WARNING: DO NOT INCLUDE THIS CLASS IN THE MANAGED PACKAGE
*
* Core Work Item: [tbd]
* Core Module: "sfdo"
*/
public without sharing class SfdoLogUtils {

    /**
     * @description 
     */
    public static void log( /* parameters TBD */ ) {
        // TBD
    }
 
}