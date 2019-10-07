Class Demo.BO.DrugInteractions Extends EnsLib.REST.Operation
{

Method GetInteractions(pRequest As Demo.Messages.DrugInteractionRequest, Output pResponse As Demo.Messages.DrugInteractionResponse) As %Status
{
	set pResponse = "", tSC = $$$OK
	try {
		
		// map RxCode to RxCUIs for submitting to server
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare("SELECT RxCUI FROM Demo_Data.Medication WHERE RxCode = ?")
		quit:$$$ISERR(tSC)
		
		set tCUIs = ""
		for i = 1:1:pRequest.RxCodes.Count() {
			
			set tResult = tStatement.%Execute(pRequest.RxCodes.GetAt(i))
			continue:'tResult.%Next()
			
			set tCUI = tResult.%GetData(1)
			set:''tCUI tCUIs = tCUIs_" "_tCUI
		}
		
		set tSC = ..QueryServer($zstrip(tCUIs,"<W"), .pResponse)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetInteractionsSimple(pRequest As Demo.Messages.DrugInteractionRequestSimple, Output pResponse As Demo.Messages.DrugInteractionResponse) As %Status
{
	quit ..QueryServer(pRequest.RxCUIs, .pResponse)
}

Method QueryServer(pCUIs As %String, Output pResponse As Demo.Messages.DrugInteractionResponse) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tURL = ..Adapter.URL_"/list.json?rxcuis="_$zcvt($zstrip(pCUIs,"<>W"),"O","URL")
		
		#dim tHTTPResponse As %Net.HttpResponse
		set tSC = ..Adapter.GetURL(tURL, .tHTTPResponse)
		
		if $$$ISERR(tSC) && $isobject(tHTTPResponse) && $isobject(tHTTPResponse.Data) && tHTTPResponse.Data.Size {
        	set tSC = $$$ERROR($$$EnsErrGeneral,$$$StatusDisplayString(tSC)_":"_tHTTPResponse.Data.Read())
      	}
      	quit:$$$ISERR(tSC)
      	
      	if $isobject(tHTTPResponse) {
	      	
	      	set pResponse = ##class(Demo.Messages.DrugInteractionResponse).%New()
	      	
	         // Convert JSON into a Proxy Object
	         set tJSON = {}.%FromJSON(tHTTPResponse.Data)
	         
	         set pResponse.FullResponse = tJSON.%ToJSON()
	         set pResponse.Disclaimer = tJSON.nlmDisclaimer
	         
	         // simplified parsing
	         if $isobject(tJSON.fullInteractionTypeGroup) {
		         set tIterator = tJSON.fullInteractionTypeGroup.%GetIterator()
		         while tIterator.%GetNext(,.tFITG) {
			         continue:'$isobject(tFITG.fullInteractionType)
			         set tIterator2 = tFITG.fullInteractionType.%GetIterator()
			         while tIterator2.%GetNext(,.tFIT) {
				         continue:'$isobject(tFIT.interactionPair)
				         set tIterator3 = tFIT.interactionPair.%GetIterator()
				         while tIterator3.%GetNext(,.tIP) {
					     	set tInteraction = ##class(Demo.Messages.DrugInteraction).%New()
					     	set tInteraction.SourceName = tFITG.sourceName
					     	set tInteraction.SourceDisclaimer = tFITG.sourceDisclaimer
					     	set tInteraction.Comment = tFIT.comment
			    	 		set tInteraction.Description = tIP.description
			     			do pResponse.Interactions.Insert(tInteraction)
				         }
			         }
		         }
	         }
      	}
       
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Demo.Messages.DrugInteractionRequest">
    <Method>GetInteractions</Method>
  </MapItem>
  <MapItem MessageType="Demo.Messages.DrugInteractionRequestSimple">
    <Method>GetInteractionsSimple</Method>
  </MapItem>
</MapItems>
}

}

