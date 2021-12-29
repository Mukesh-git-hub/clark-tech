public with sharing class CLRK_ConfigsController {
    public static final String ENDPOINT = 'https://case-configs.requestcatcher.com/';
    
    @AuraEnabled(Cacheable=true)
    public static list<Config__c> getAllConfigs(){
        try {
            List<Case_Config__c> allCaseCofigsLst = new List<Case_Config__c>();
            List<Config__c> availableCofigsLst = new List<Config__c>();
            Set<String> labelsSet = new Set<String>();
            allCaseCofigsLst = [SELECT Id, Name, Label__c, Type__c, Amount__c FROM 
                                Case_Config__c LIMIT 49999];
            for(Case_Config__c oCaseConfig : allCaseCofigsLst){
                labelsSet.add(oCaseConfig.Label__c);
            }
            availableCofigsLst = [SELECT Id, Name, Label__c, Type__c, Amount__c FROM 
                                  Config__c WHERE Label__c NOT IN:labelsSet  LIMIT 49999];
            return availableCofigsLst;
            
            
        } catch (Exception e) {
            system.debug('Capturing the expection - Message'+e.getMessage()+'   Line no'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    @AuraEnabled(Cacheable=true)
    public static list<Case_Config__c> getAllCaseConfigs(String caseId){
        try {
            List<Case_Config__c> allCaseCofigsLst = new List<Case_Config__c>();
            allCaseCofigsLst = [SELECT Id, Name, Label__c, Type__c, Amount__c,Case__c 
                                FROM Case_Config__c WHERE Case__c =:caseId LIMIT 49999];
            
            return allCaseCofigsLst;
        } catch (Exception e) {
            system.debug('Capturing the expection - Message'+e.getMessage()+'   Line no'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    @AuraEnabled
    public static void addConfigsToCase(List<Config__c> configsLst,Id caseId){
        try {
            List<Case_Config__c> newCaseCofigsLst = new List<Case_Config__c>();
            for(Config__c oConfig : configsLst){
                newCaseCofigsLst.add(new Case_Config__c(Case__c = caseId,
                                                        Label__c=oConfig.Label__c,
                                                        Amount__c=oConfig.Amount__c,
                                                        Type__c=oConfig.Type__c));
            }
            if(! newCaseCofigsLst.isEmpty()){
                insert newCaseCofigsLst;
            }
            
        } catch (Exception e) {
            system.debug('Capturing the expection - Message'+e.getMessage()+'   Line no'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void handleCaseSend(List<Case_Config__c> caseConfigsLst,String caseId){
        try {
            String requestBody = '';
			Savepoint sp;
            // Create a savepoint before updating the case
            if(!Test.isRunningTest()){ sp = Database.setSavepoint(); }
            
            JSONGenerator oJSONGenerator = JSON.createGenerator(true);             
            oJSONGenerator.writeStartObject();
            if(String.isNotEmpty(caseId))
            oJSONGenerator.writeStringField('caseId',caseId);
            oJSONGenerator.writeStringField('status','Closed');
            oJSONGenerator.writeFieldName('caseConfigs');
            oJSONGenerator.writeStartArray();
            for(Case_Config__c oConfig :caseConfigsLst){
                
                oJSONGenerator.writeStartObject();
                    if(String.isNotEmpty(oConfig.Label__c))
                    oJSONGenerator.writeStringField('label', oConfig.Label__c);
                    if(String.isNotEmpty(oConfig.Type__c))
                    oJSONGenerator.writeStringField('type', oConfig.Type__c);
                    if(String.isNotEmpty(String.valueOf(oConfig.Amount__c)))
                    oJSONGenerator.writeStringField('amount', String.valueOf(oConfig.Amount__c));
                oJSONGenerator.writeEndObject();
            }
            oJSONGenerator.writeEndArray();
            oJSONGenerator.writeEndObject();
            requestBody = oJSONGenerator.getAsString();

            Case oCase = new Case(Id=caseId,Status='Closed');            
            update oCase;

            try{
                if(String.isNotEmpty(requestBody))
                {
                	sendDataToExternalSystem(requestBody);    
                }
            }
            catch (Exception e) {
                // Rollback to the previous case status
                if(!Test.isRunningTest()){ Database.rollback(sp); }
            }

        } catch (Exception e) {
            system.debug('Capturing the expection - Message'+e.getMessage()+'   Line no'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @future(callout=true)
    public static void sendDataToExternalSystem(String requestBody){

        // Instantiate a new HTTP request, specify the method (POST) as well as the endpoint             
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/json');              
        request.setEndpoint(ENDPOINT);             
        request.setMethod('POST');
        request.setBody(requestBody);   

        // Send the request, and return a response
        Http http = new Http();             
        HttpResponse  response = http.send(request);
        if (response.getStatusCode() == 200) 
        {
            system.debug('Successfully posted to ex system');
        }
        else 
        {
            system.debug('Capturing the expection - Status Code'+response.getStatusCode()+'     Message'+response.getBody());
        }
    }
}