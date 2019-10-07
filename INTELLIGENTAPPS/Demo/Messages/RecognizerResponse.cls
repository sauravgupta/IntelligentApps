Class Demo.Messages.RecognizerResponse Extends Ens.Response
{

Property PrescriberID As %String(MAXLEN = 50);

Property Medications As list Of RxTermScannerItem(XMLITEMNAME = "Item", XMLPROJECTION = "ELEMENT");

Storage Default
{
<Data name="RecognizerResponseDefaultData">
<Subscript>"RecognizerResponse"</Subscript>
<Value name="1">
<Value>PrescriberID</Value>
</Value>
<Value name="2">
<Value>Medications</Value>
</Value>
</Data>
<DefaultData>RecognizerResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

