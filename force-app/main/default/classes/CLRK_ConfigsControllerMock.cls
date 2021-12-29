@isTest
global class CLRK_ConfigsControllerMock implements HttpCalloutMock{
    
	global HttpResponse respond(HttpRequest rep)
    {
        HttpResponse res = new HttpResponse();
        res.setStatus('Request is accepted');         
        res.setBody('{"message":"Successfully Posted"}');
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        return res;
    }  
    
    
}