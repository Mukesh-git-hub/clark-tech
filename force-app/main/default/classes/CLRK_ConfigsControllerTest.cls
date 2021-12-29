@isTest
public class CLRK_ConfigsControllerTest {
	@testSetup  
    static void testSetupMethod()        
    {
        //Setting up case data
       	Case oCase = new Case();
        oCase.Origin = 'Email';
        oCase.Status = 'New';
        oCase.Subject = 'My configs are not working';
        oCase.Description = 'Getting some issues with my configs';
        insert oCase;
        
        //Setting up config data
        Config__c oConfig = new Config__c();
        oConfig.Label__c = 'all config';
        oConfig.Type__c = 'Type 1';
        oConfig.Amount__c = 22.1;
        insert oConfig;
        
        //Setting up config data
        Case_Config__c oCaseConfig = new Case_Config__c();
        oCaseConfig.Label__c = 'new config';
        oCaseConfig.Type__c = 'Type 3';
        oCaseConfig.Amount__c = 22.1;
        oCaseConfig.Case__c = oCase.Id;
        insert oCaseConfig;

    }
    @isTest
    static void getAllConfigsTest() {
        
        List<Case_Config__c> allCaseCofigsLst  = [SELECT Id, Name, Label__c, Type__c, Amount__c FROM Case_Config__c WHERE Label__c = 'new config'];
    	List<Config__c> availableCofigsLst = [SELECT Id, Name, Label__c, Type__c, Amount__c FROM Config__c WHERE Label__c = 'all config'];
        Test.startTest();
        	CLRK_ConfigsController.getAllConfigs();
        Test.stopTest();
        System.assertEquals(1,allCaseCofigsLst.size());
        System.assertEquals(1,availableCofigsLst.size());
    }    
    @isTest
    static void getAllCaseConfigsTest() {
        
        Case oCase = [Select Id from Case WHERE Status = 'New' Limit 1];
        List<Case_Config__c> allCaseCofigsLst  = [SELECT Id, Name, Label__c, Type__c, Amount__c,Case__c FROM Case_Config__c WHERE Label__c = 'new config'];
    	List<Config__c> availableCofigsLst = [SELECT Id, Name, Label__c, Type__c, Amount__c FROM Config__c WHERE Label__c = 'all config'];
        Test.startTest();
        	CLRK_ConfigsController.getAllCaseConfigs(oCase.Id);
        Test.stopTest();
        System.assertEquals(1,allCaseCofigsLst.size());
    }
    @isTest
    static void addConfigsToCaseTest() {
        
        Case oCase = [Select Id from Case WHERE Status = 'New' Limit 1];
    	List<Config__c> availableCofigsLst = [SELECT Id, Name, Label__c, Type__c, Amount__c FROM Config__c WHERE Label__c = 'all config'];
        Test.startTest();
        	CLRK_ConfigsController.addConfigsToCase(availableCofigsLst,oCase.Id);
        Test.stopTest();
        System.assertEquals(1,availableCofigsLst.size());
    }
    @isTest
    static void handleCaseSendTest() {
        
        Case oCase = [Select Id from Case WHERE Status = 'New' Limit 1];
        List<Case_Config__c> allCaseCofigsLst  = [SELECT Id, Name, Label__c, Type__c, Amount__c,Case__c FROM Case_Config__c WHERE Label__c = 'new config'];
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new CLRK_ConfigsControllerMock());     
        	CLRK_ConfigsController.handleCaseSend(allCaseCofigsLst,oCase.Id);
        Test.stopTest();
    }
}