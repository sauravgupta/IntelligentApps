Class Demo.BO.REST.AzureAdapter Extends Adapter
{

Parameter SETTINGS = "AzureSubscriptionKey";

Property AzureSubscriptionKey As %String(MAXLEN = 256);

Method AddAuthorization(ByRef pHttpRequest As %Net.HttpRequest, pMethod As %String = "POST") As %Status
{
	set tSC = $$$OK
	try {
		
		do pHttpRequest.SetHeader("Ocp-Apim-Subscription-Key", ..AzureSubscriptionKey)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

// TODO: remove before sharing!
ClassMethod Test() As %Status
{
	set tSC = $$$OK
	try {
		
		set tAdapter = ..%New()
		set tAdapter.Host = "westeurope.api.cognitive.microsoft.com"
		set tAdapter.SSLConfig = "SSL client" // simple empty SSL config
		set tAdapter.BaseURL = "/vision/v1.0/ocr"
		set tAdapter.AzureSubscriptionKey = "0323ace8f8dc47e7bfc1d505284ed412"
		
		set tRequestBody = { "url": "https://www.intersystems.com/wp-content/uploads/2018/12/CloudPartners.jpg"}
		set tSC = tAdapter.Post(.tResponseBody, .tResponseHeaders, tRequestBody)
		//quit:$$$ISERR(tSC)
		
		w !!,"Response headers:",! zw tResponseHeaders
		
		w:$isobject(tResponseBody) !!,"Response body:",!,tResponseBody.%ToJSON()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	w:$$$ISERR(tSC) !!,$system.Status.GetErrorText(tSC),!
	quit tSC
}

}

