Class Demo.Messages.OCRResponse Extends Ens.Response
{

Property ExtractedText As %String(MAXLEN = "");

Property FullResponse As %String(MAXLEN = "");

Storage Default
{
<Data name="OCRResponseDefaultData">
<Subscript>"OCRResponse"</Subscript>
<Value name="1">
<Value>ExtractedText</Value>
</Value>
<Value name="2">
<Value>FullResponse</Value>
</Value>
</Data>
<DefaultData>OCRResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

