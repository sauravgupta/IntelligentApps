Class Demo.BS.ReceiptReader Extends Ens.BusinessService [ Hidden ]
{

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

Parameter SETTINGS = "TargetConfigName::selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Property TargetConfigName As %String(MAXLEN = 1000);

Method OnProcessInput(pInputFile As %FileBinaryStream, Output pRequest As %RegisteredObject) As %Status
{
   set tSC=$$$OK, pRequest=""
   try {
	   
	   set pRequest = ##class(Demo.Messages.ReceiptRequest).%New()
	   set pRequest.FileName = pInputFile.Filename
	   set tSC = pRequest.ImageData.CopyFromAndSave(pInputFile)
	   quit:$$$ISERR(tSC)
	   
	   set tSC = ..SendRequestAsync(..TargetConfigName,pRequest)
	   quit:$$$ISERR(tSC)
	   
   } catch (ex) {
	   set tSC = ex.AsStatus()
   }
   quit tSC
}

/// This method is called when Portal is drawing the production diagram
/// pArray contains the config names the scanner found.
/// Users can remove or add new names
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	if pItem.GetSetting("TargetConfigName", .tTarget) {
		set pArray(tTarget)=""
	}
	Quit
}

}

