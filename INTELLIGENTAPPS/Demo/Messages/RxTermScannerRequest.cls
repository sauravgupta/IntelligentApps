Class Demo.Messages.RxTermScannerRequest Extends Ens.Request
{

Property RawText As %String(MAXLEN = "");

Storage Default
{
<Data name="RxTermScannerRequestDefaultData">
<Subscript>"RxTermScannerRequest"</Subscript>
<Value name="1">
<Value>RawText</Value>
</Value>
</Data>
<DefaultData>RxTermScannerRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

