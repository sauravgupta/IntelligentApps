Class Demo.BO.RxTermScanner Extends Ens.BusinessOperation [ Deprecated, Hidden ]
{

Method ScanText(pRequest As Demo.Messages.RxTermScannerRequest, Output pResponse As Demo.Messages.RxTermScannerResponse) As %Status
{
	set tSC = $$$OK
	try {
		set pResponse = ##class(Demo.Messages.RxTermScannerResponse).%New()
		
		// use a regexp to ensure dosages are split off
		set tSplitDosages = ##class(%Regex.Matcher).%New("([a-zA-Z\-\.])([0-9]+(MG|mg|GM))")
		
		// there's much faster ways, but let's go with this now
		set tLineBreak = $c(13,10), tLineCount = $l(pRequest.RawText,tLineBreak)
		for i = 1:1:tLineCount {
			set tLine = $piece(pRequest.RawText,tLineBreak,i)
			
			// skip lines with just punctuation or numbers
			continue:$zstrip(tLine,"*NCP")=""
			
			// split off dosages
			set tSplitDosages.Text = tLine,
				tLine = tSplitDosages.ReplaceAll("$1 $2")
				
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
				continue:$$$ISERR(..FindRxTerm(tToken, .tDrugName, .tRxCUI, .tFound))||'tFound
				
				set tItem = ##class(Demo.Messages.RxTermScannerItem).%New()
				set tItem.DrugName = tDrugName,
					tItem.RxCUI = tRxCUI,
					tItem.SourceLine = tLine,
					tItem.SourceToken = tToken
					
				do pResponse.Items.Insert(tItem)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
		$$$LOGSTATUS(tSC)
	}
	quit tSC
}

Property SearchStatement As %SQL.Statement [ Internal, Private ];

Method FindRxTerm(pToken As %String, Output pDrugName As %String, Output pRxCUI As %String, Output pFound As %Boolean) As %Status
{
	set tSC = $$$OK, pFound = 0, pDrugName="", pRxCUI=""
	try {
		if (..SearchStatement="") {
			set ..SearchStatement = ##class(%SQL.Statement).%New()
			set tSC = ..SearchStatement.%Prepare("SELECT RxCUI, PSN FROM Demo_Data.RxTerm WHERE %ID %FIND search_index(iFind, ?, ?)")
			quit:$$$ISERR(tSC)
		}
		
		// first try to find straight matches, then check fuzzy mode
		for tSearchMode = 0, 3 {
			set tResult = ..SearchStatement.%Execute(pToken, tSearchMode)
			continue:'tResult.%Next()
			set pDrugName = tResult.%GetData(2), 
				pRxCUI = tResult.%GetData(1), 
				pFound = 1
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
  <MapItem MessageType="Demo.Messages.RxTermScannerRequest">
    <Method>ScanText</Method>
  </MapItem>
</MapItems>
}

}

