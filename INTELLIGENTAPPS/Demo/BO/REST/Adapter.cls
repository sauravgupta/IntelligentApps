Class Demo.BO.REST.Adapter Extends Ens.OutboundAdapter [ Abstract ]
{

Parameter SETTINGS = "Host,BaseURL,SSLConfig::sslConfigSelector";

Property Host As %String(MAXLEN = 200);

Property BaseURL As %String(MAXLEN = 200);

Property SSLConfig As %String;

// Property ContentType As %String [ InitialExpression = "application/json" ];
Method BuildRequest(Output pHttpRequest As %Net.HttpRequest) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		if ..Host="" {
			set tSC = $$$ERROR($$$GeneralError, "No value for Host setting")
			quit
		}
		if ..BaseURL="" {
			set tSC = $$$ERROR($$$GeneralError, "No value for BaseURL setting")
			quit
		}
		
		set pHttpRequest = ##class(%Net.HttpRequest).%New()
		set pHttpRequest.Server = ..Host
		if ..SSLConfig'="" {
			set pHttpRequest.Https = 1
			set pHttpRequest.Port = 443
			set pHttpRequest.SSLConfiguration = ..SSLConfig
		} else {
			set pHttpRequest.Port = 80
		}
		//set pHttpRequest.ContentType = ..ContentType
		
		do pHttpRequest.SetHeader("Host", ..Host)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
		$$$LOGSTATUS(tSC)
	}
	quit tSC
}

Method AddAuthorization(ByRef pHttpRequest As %Net.HttpRequest, pMethod As %String = "POST") As %Status [ Abstract ]
{
	quit $$$OK
}

Method Post(Output pResponseBody As %DynamicObject, Output pResponseHeaders, pBody) As %Status
{
	kill pResponseHeaders
	set tSC = $$$OK, pResponseBody=""
	try {
		
		#dim tHttpRequest as %Net.HttpRequest
		set tSC = ..BuildRequest(.tHttpRequest)
		quit:$$$ISERR(tSC)
		
		if '$isobject(pBody) {
			$$$LOGWARNING("Unknown content type, defaulting to text/plain")
			set tHttpRequest.ContentType = "text/plain"
			set tSC = tHttpRequest.EntityBody.Write(pBody)
			quit:$$$ISERR(tSC)
		} elseif pBody.%IsA("%DynamicObject") {
			set tHttpRequest.ContentType = "application/json"
			set tSC = tHttpRequest.EntityBody.Write(pBody.%ToJSON())
			quit:$$$ISERR(tSC)
		} elseif pBody.%IsA("%Stream.Object") {
			set tHttpRequest.ContentType = "application/octet-stream"
			set tSC = tHttpRequest.EntityBody.CopyFrom(pBody)
			quit:$$$ISERR(tSC)
		} else {
			// unknown format, just try to dump as is
			$$$LOGWARNING("Unknown content type, posting as-is")
			set tSC = tHttpRequest.EntityBody.Write(pBody)
			quit:$$$ISERR(tSC)
		}
		
		$$$LOGINFO("Adding Authorization headers for "_$classname())
		set tSC = ..AddAuthorization(.tHttpRequest, "POST")
		quit:$$$ISERR(tSC)
		
		set tSC = tHttpRequest.Post(..BaseURL)
		quit:$$$ISERR(tSC)
		
		if '$isobject(tHttpRequest.HttpResponse) {
			set tSC = $$$ERROR($$$GeneralError, "No response from server")
			quit
		}
		
		if tHttpRequest.HttpResponse.StatusCode'=200 {
			set tSC = $$$ERROR($$$GeneralError, "HTTP Response: "_tHttpRequest.HttpResponse.StatusCode_" - "_tHttpRequest.HttpResponse.StatusLine)
			quit
		}
		merge pResponseHeaders = tHttpRequest.HttpResponse.Headers
		
		if '$isobject(tHttpRequest.HttpResponse.Data) {
			set tSC = $$$ERROR($$$GeneralError, "Empty response stream")
			quit
		}
		
		set pResponseBody = ##class(%DynamicObject).%FromJSON(tHttpRequest.HttpResponse.Data)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
		$$$LOGSTATUS(tSC)
	}
	quit tSC
}

}

