@isTest
public with sharing class STTG_InstallScript_TEST {

    public testmethod static void runScript() {
        
        STTG_InstallScript script = new STTG_InstallScript();
        
        //@TODO: we should be reading the version number from a config file
        Test.testInstall(script, new Version(1,0));
        
        
    } 
}