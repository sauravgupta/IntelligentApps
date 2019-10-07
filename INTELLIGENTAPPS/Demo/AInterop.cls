Class Demo.AInterop Extends Ens.Production
{

Parameter LSMSCredentialName = "LSMailServer";

/// Override this in your Production class to do setup before the Production starts
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
	set tStudentEmail = $system.Util.GetEnviron("AVL_STUDENT_ID")
	
	if '(##class(Ens.Config.Credentials).%ExistsId(..#LSMSCredentialName)) {
		set MailboxName = "gs19user"_..GetRandomUsername()_"@intersystemslabs.com"
		
		set tSC = ##class(Ens.Config.Credentials).SetCredential(..#LSMSCredentialName, MailboxName, "Intersystems19")
		set tSettings("Email reader","Adapter","MailboxName") = MailboxName 
		do ..ApplySettings("Demo.AInterop", .tSettings)
		quit:$$$ISERR(tSC)
	}
	
	if tStudentEmail'="" {
		set tSettings("Email reader","Adapter","MatchFrom") = tStudentEmail 
		quit ..ApplySettings("Demo.AInterop", .tSettings)
	} else {
		quit $$$OK
	}
}

ClassMethod GetRandomUsername() As %String
{
	set list= $LISTBUILD("01","02","03","04","05","06","07","08","09","10",
						 "11","12","13","14","15","16","17","18","19","20",
						 "21","22","23","24","25","26","27","28","29","30",
						 "31","32","33","34","35","36","37","38","39","40",
						 "41","42","43","44","45","46","47","48","49","50")
	QUIT ($LI(list,$RANDOM($LL(list))+1))
}

XData ProductionDefinition
{
<Production Name="Demo.AInterop" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>Demo production for AI-infused business process</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="Drug Interactions" Category="External services" ClassName="Demo.BO.DrugInteractions" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="HTTPPort">443</Setting>
    <Setting Target="Adapter" Name="HTTPServer">rxnav.nlm.nih.gov</Setting>
    <Setting Target="Adapter" Name="URL">/REST/interaction</Setting>
    <Setting Target="Adapter" Name="SSLCheckServerIdentity">0</Setting>
    <Setting Target="Adapter" Name="SSLConfig">SSL client</Setting>
  </Item>
  <Item Name="Text Extraction" Category="External services" ClassName="Demo.BO.OCRService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="SSLConfig">SSL client</Setting>
    <Setting Target="Adapter" Name="AzureSubscriptionKey">ee7ce19eb27848ec980214706c55a6d4</Setting>
    <Setting Target="Adapter" Name="BaseURL">/vision/v1.0/ocr</Setting>
    <Setting Target="Adapter" Name="Host">compvisgsd2019.cognitiveservices.azure.com</Setting>
  </Item>
  <Item Name="Email reader" Category="" ClassName="Demo.BS.EmailReader" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="Credentials">GMail demo account</Setting>
    <Setting Target="Adapter" Name="IMAPPort">993</Setting>
    <Setting Target="Adapter" Name="IMAPServer">imap.gmail.com</Setting>
    <Setting Target="Adapter" Name="SSLConfig">SSL client</Setting>
    <Setting Target="Adapter" Name="SeachAllMailboxes">1</Setting>
    <Setting Target="Host" Name="TargetConfigName">Receipt Processing</Setting>
    <Setting Target="Adapter" Name="MatchFrom">saurav.gupta@intersystems.com</Setting>
    <Setting Target="Adapter" Name="DeleteFromServer">1</Setting>
    <Setting Target="Adapter" Name="MailboxName">IRISDemo123@gmail.com</Setting>
  </Item>
  <Item Name="Response Email" Category="" ClassName="Demo.BO.EMailResponder" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="Credentials">GMail demo account</Setting>
    <Setting Target="Adapter" Name="SMTPPort">465</Setting>
    <Setting Target="Adapter" Name="SMTPServer">smtp.gmail.com</Setting>
    <Setting Target="Adapter" Name="SSLConfig">SSL client</Setting>
  </Item>
  <Item Name="Recognizer" Category="" ClassName="Demo.BO.Recognizer" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Registry Lookup" Category="" ClassName="Demo.BO.RegistryLookup" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="invoke PMML generic" Category="" ClassName="PMML.Interop.BusinessOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="PMMLClassName">Demo.PMML.MyModel</Setting>
  </Item>
  <Item Name="Receipt Processing" Category="" ClassName="Demo.BPL.ReceiptProcessWithML" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
