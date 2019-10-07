Class Demo.BO.Recognizer Extends Ens.BusinessOperation
{

Method Recognize(pRequest As Demo.Messages.RecognizerRequest, pResponse As Demo.Messages.RecognizerResponse) As %Status
{
	set tSC = $$$OK
	try {
		set pResponse = ##class(Demo.Messages.RecognizerResponse).%New()
		set tNormalizedText = $zstrip($tr(pRequest.RawText,$c(13,10,9),"   "),"=W")
		
		// 1. Identify prescriber ID
		set tRegexPrescriber = ##class(%Regex.Matcher).%New("(prescriber|Prescriber|PRESCRIBER)( ID)?:? ([0-9a-zA-Z]+)", tNormalizedText)
		if tRegexPrescriber.Locate() {
			set pResponse.PrescriberID = tRegexPrescriber.Group(3)
		}
		
		// 2. Identify medications
		
		// 2.1. Through matching against the Demo.Data.Medication table
		// 		(there's much faster ways than this, but let's go with this now)
		set tLineBreak = $c(13,10), tLineCount = $l(pRequest.RawText,tLineBreak)
		for i = 1:1:tLineCount {
			set tLine = $piece(pRequest.RawText,tLineBreak,i)
			
			// skip lines with just punctuation or numbers
			continue:$zstrip(tLine,"*NCP")=""
				
			set tTokenCount = $l(tLine," ")
			for j = 1:1:tTokenCount {
				set tToken = $$$LOWER($p(tLine," ",j))
				
				// skip numeric tokens
				continue:$zstrip(tToken,"*NCP")=""
				
				// skip classic tokens
				continue:tToken="subtotal"
				continue:tToken="total"
				continue:tToken="tax"
				
				// skip really short stuff
				continue:$l($zstrip(tToken,"*NCP"))<3
				
				// now search any other token
				set tSC = ..FindMedication(tToken, .tDrugName, .tRxCode, .tFound)
				quit:$$$ISERR(tSC)
				continue:'tFound
				
				set tItem = ##class(Demo.Messages.RxTermScannerItem).%New()
				set tItem.DrugName = tDrugName,
					tItem.RxCode = tRxCode,
					tItem.SourceLine = tLine,
					tItem.SourceToken = tToken
					
				do pResponse.Medications.Insert(tItem)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// 2.2. Check hard references
		set tRegexRX = ##class(%Regex.Matcher).%New("rx ([0-9]+)", tNormalizedText)
		while tRegexRX.Locate() {
			set tItem = ##class(Demo.Messages.RxTermScannerItem).%New()
			set tItem.DrugName = "",
				tItem.RxCode = tRegexRX.Group(1),
				tItem.SourceToken = tRegexRX.Group
			do pResponse.Medications.Insert(tItem)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
		$$$LOGSTATUS(tSC)
	}
	quit tSC
}

Property SearchStatement As %SQL.Statement [ Internal, Private ];

Method FindMedication(pToken As %String, Output pDrugName As %String, Output pRxCUI As %String, Output pFound As %Boolean) As %Status
{
	set tSC = $$$OK, pFound = 0, pDrugName="", pRxCUI=""
	try {
		if (..SearchStatement="") {
			set ..SearchStatement = ##class(%SQL.Statement).%New()
			set tSC = ..SearchStatement.%Prepare("SELECT RxCode, Product FROM Demo_Data.Medication WHERE %ID %FIND search_index(iFind, ?, ?)")
			quit:$$$ISERR(tSC)
		}
		
		// first try to find straight matches, then check fuzzy mode
		for tSearchMode = 0, 3 {
			set tResult = ..SearchStatement.%Execute(pToken, tSearchMode)
			continue:'tResult.%Next()
			set pDrugName = tResult.%GetData(2), 
				pRxCUI = tResult.%GetData(1), 
				pFound = 1
				
			quit // exit if we found an exact match
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
		$$$LOGSTATUS(tSC)
	}
	quit tSC
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Demo.Messages.RecognizerRequest">
    <Method>Recognize</Method>
  </MapItem>
</MapItems>
}

}

