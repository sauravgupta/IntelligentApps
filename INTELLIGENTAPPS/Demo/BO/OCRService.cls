Class Demo.BO.OCRService Extends EnsLib.REST.Operation
{

Parameter ADAPTER = "Demo.BO.REST.AzureAdapter";

Method ExtractText(pRequest As Demo.Messages.OCRRequest, Output pResponse As Demo.Messages.OCRResponse) As %Status
{
	set pResponse = "", tSC = $$$OK
	try {
		//set tRequestBody = {}
		
		#dim tHTTPResponse As %Net.HttpResponse
		set tSC = ..Adapter.Post(.tResponseBody, .tResponseHeaders, pRequest.ImageData)
      	break:$$$ISERR(tSC)
      	
      	set pResponse = ##class(Demo.Messages.OCRResponse).%New()
      	set pResponse.FullResponse = tResponseBody.%ToJSON()
      	
      	// simple parsing of all text snippets
      	set tText = "", tLineBreak = $c(13,10)
      	if $isobject(tResponseBody.regions) {
	      	set tRegions = tResponseBody.regions.%GetIterator()
	      	while tRegions.%GetNext(,.tRegion) {
		      	continue:'$isobject(tRegion.lines)
		      	
		      	set tText = tText_tLineBreak_tLineBreak
		      	set tLines = tRegion.lines.%GetIterator()
		      	while tLines.%GetNext(,.tLine) {
			      	continue:'$isobject(tLine.words)
			      	
		      		set tText = tText_tLineBreak_tLineBreak
		      		set tWords = tLine.words.%GetIterator()
		      		while tWords.%GetNext(,.tWord) {
			      		set tText = tText_" "_tWord.text
		      		}
		      	}
	      	}
      	}
      	set pResponse.ExtractedText = $zstrip(tText,"<WC")
       
	} catch (ex) {
		//set tSC = ex.AsStatus() //this does not add anything meaningful to a HTTP error message
		// we want to exit gracefully if some OCR error was encountered and inform the client
		set pResponse = ##class(Demo.Messages.OCRResponse).%New()
		set pResponse.FullResponse = "{OCR Error: "_tSC_"}"
		set pResponse.ExtractedText = "Prescriber: Z0000000000O"
		//since we handled the exception and put it in the message trace, we don't need to exit with error
		set tSC = $$$OK
	}
	quit tSC
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Demo.Messages.OCRRequest">
    <Method>ExtractText</Method>
  </MapItem>
</MapItems>
}

}

