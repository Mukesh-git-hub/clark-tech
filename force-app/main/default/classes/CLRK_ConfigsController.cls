public with sharing class CLRK_ConfigsController {
    
    public static final String ENDPOINT = 'https://case-configs.requestcatcher.com/';

    //Method to get all available configs which will filter out cofigs in case object
    @AuraEnabled(Cacheable=true)
    public static list<Config__c> getAllConfigs(){
        try {
            List<Case_Config__c> allCaseCofigsLst = new List<Case_Config__c>();
            List<Config__c> availableCofigsLst = new List<Config__c>();
            Set<String> labelsSet = new Set<String>();
            allCaseCofigsLst = [SELECT Id, Name, Label__c, Type__c, Amount__c FROM Case_Config__c LIMIT 49999];
            for(Case_Config__c oCaseConfig : allCaseCofigsLst){
                labelsSet.add(oCaseConfig.Label__c);
            }
            availableCofigsLst = [SELECT Id, Name, Label__c, Type__c, Amount__c FROM Config__c WHERE Label__c NOT IN:labelsSet  LIMIT 49999];
            return availableCofigsLst;
        } catch (Exception e) {
            system.debug('Capturing the expection - Message'+e.getMessage()+'   Line no'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    //Method to get All Case Configs
    @AuraEnabled(Cacheable=true)
    public static list<Case_Config__c> getAllCaseConfigs(String caseId){
        try {
            List<Case_Config__c> allCaseCofigsLst = new List<Case_Config__c>();
            allCaseCofigsLst = [SELECT Id, Name, Label__c, Type__c, Amount__c,Case__c FROM Case_Config__c WHERE Case__c =:caseId LIMIT 49999];
            return allCaseCofigsLst;
        } catch (Exception e) {
            system.debug('Capturing the expection - Message'+e.getMessage()+'   Line no'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    //Method to add new configs to case
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

    //Method to handle the case send - Updating the case status with closed and making a call external system with case cofigs data
    @AuraEnabled
    public static void handleCaseSend(List<Case_Config__c> caseConfigsLst,String caseId){
        try {
            String requestBody = '';

            // Create a savepoint before updating the case
            Savepoint sp = Database.setSavepoint();

            JSONGenerator oJSONGenerator = JSON.createGenerator(true);             
            oJSONGenerator.writeStartObject();
            oJSONGenerator.writeStringField('caseId',caseId);
            oJSONGenerator.writeStringField('status','Closed');
            oJSONGenerator.writeFieldName('caseConfigs');
            oJSONGenerator.writeStartArray();
            for(Case_Config__c oConfig :caseConfigsLst){
                oJSONGenerator.writeStartObject();
                oJSONGenerator.writeStringField('label', oConfig.Label__c);
                oJSONGenerator.writeStringField('type', oConfig.Type__c);
                oJSONGenerator.writeStringField('amount', String.valueOf(oConfig.Amount__c));
                oJSONGenerator.writeEndObject();
            }
            oJSONGenerator.writeEndArray();
            oJSONGenerator.writeEndObject();
            requestBody = oJSONGenerator.getAsString();

            Case oCase = new Case(Id=caseId,Status='Closed');            
            update oCase;

            try{
                sendDataToExternalSystem(requestBody);
            }
            catch (Exception e) {

                // Rollback to the previous case status
                Database.rollback(sp);
            }

        } catch (Exception e) {
            system.debug('Capturing the expection - Message'+e.getMessage()+'   Line no'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Common method to make http callout
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
        if (response.getStatusCode() == 202) 
        {
            system.debug('Successfully posted to ex system');
        }
        else 
        {
            system.debug('Capturing the expection - Status Code'+response.getStatusCode()+'     Message'+response.getBody());
        }
    }
}
