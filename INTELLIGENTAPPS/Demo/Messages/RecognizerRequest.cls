Class Demo.Messages.RecognizerRequest Extends Ens.Request
{

Property RawText As %String(MAXLEN = "");

Storage Default
{
<Data name="RecognizerRequestDefaultData">
<Subscript>"RecognizerRequest"</Subscript>
<Value name="1">
<Value>RawText</Value>
</Value>
</Data>
<DefaultData>RecognizerRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

