Class Demo.Util.Functions Extends Ens.Rule.FunctionSet
{

/// extracts the RxCode properties of the supplied list and puts them in a new list	
ClassMethod ExtractRxCodes(pListOfRxTermScannerItems As %ListOfObjects) As %ListOfDataTypes
{
	#dim tItem as Demo.Messages.RxTermScannerItem
	set tNewList = ##class(%ListOfDataTypes).%New()
	if $isobject(pListOfRxTermScannerItems) {
		for i = 1:1:pListOfRxTermScannerItems.Count() {
			set tItem = pListOfRxTermScannerItems.GetAt(i)
			do tNewList.Insert(tItem.RxCode)
		}
	}
	quit tNewList
}

/// Extracts the Rxcode properties of the supplied list and puts them into an array with some "invented" dosage
ClassMethod ExtractRxCodesAndInventDosage(pListOfRxTermScannerItems As %ListOfObjects) As %ArrayOfDataTypes
{
	#dim tItem as Demo.Messages.RxTermScannerItem
	set tNewArray = ##class(%ArrayOfDataTypes).%New()
	if $isobject(pListOfRxTermScannerItems) {
		for i = 1:1:pListOfRxTermScannerItems.Count() {
			set tItem = pListOfRxTermScannerItems.GetAt(i)
			// generate a random value for frequency for each RxCode in the list
			set tFreq = $normalize(($random(99)/33)**2,0)
			do tNewArray.SetAt(tFreq,tItem.RxCode)
		}
	}
	quit tNewArray
}

ClassMethod ListLength(pList As %Collection.AbstractList) As %Boolean
{
	quit:pList="" 0
	quit:$lv(pList) $ll(pList)
	quit:$isobject(pList)&&pList.%Extends("%Collection.AbstractList") pList.Count()
	quit -1
}

/// this method appends the prescription list, each item of which gets prefixed with "Rx", to the patient's medication history and sends the modified history back
ClassMethod AppendMedsToHistory(ByRef pArrayOfRxCodeHistoryItems As %ArrayOfDataTypes, pListOfRxCodePrescritptionItems As %ListOfDataTypes) As %ArrayOfDataTypes
{
	if $isobject(pArrayOfRxCodeHistoryItems) && $isobject(pListOfRxCodePrescritptionItems)
	{
		for i = 1:1:pListOfRxCodePrescritptionItems.Count(){
			// generate a random value for frequency for each RxCode in the list
			set tFreq = $normalize(($random(99)/33)**2,0)
			// and prefix the prescriptions with "Rx" before sticking them on the array
			do pArrayOfRxCodeHistoryItems.SetAt(tFreq,("Rx"_pListOfRxCodePrescritptionItems.GetAt(i))) 
		}
	}
	quit pArrayOfRxCodeHistoryItems
}

/// this method appends one array to another array and returns the resulting array
ClassMethod AppendArrays(ByRef pArrayOfRxCodeHistoryItems As %ArrayOfDataTypes, pArrayOfRxCodePrescritptionItems As %ArrayOfDataTypes) As %ArrayOfDataTypes
{
	if $isobject(pArrayOfRxCodeHistoryItems) && $isobject(pArrayOfRxCodePrescritptionItems)
	{
		set tKey = ""
		for {
			set tValue = pArrayOfRxCodePrescritptionItems.GetNext(.tKey)
			quit:tKey=""
			do pArrayOfRxCodeHistoryItems.SetAt(tValue,tKey)
		}
	}
	quit pArrayOfRxCodeHistoryItems
}

}

