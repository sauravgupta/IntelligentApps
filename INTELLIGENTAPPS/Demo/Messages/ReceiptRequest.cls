Class Demo.Messages.ReceiptRequest Extends Ens.Request
{

Property FileName As %String(MAXLEN = 200);

Property SenderEMail As %String(MAXLEN = 500);

Property OriginalSubject As %String(MAXLEN = 500);

Property ImageData As %Stream.GlobalBinary;

Property OriginalDate As %String(MAXLEN = 200);

Property OriginalText As %String(MAXLEN = "");

Storage Default
{
<Data name="ReceiptRequestDefaultData">
<Subscript>"ReceiptRequest"</Subscript>
<Value name="1">
<Value>ImageData</Value>
</Value>
<Value name="2">
<Value>FileName</Value>
</Value>
<Value name="3">
<Value>SenderEMail</Value>
</Value>
<Value name="4">
<Value>OriginalSubject</Value>
</Value>
<Value name="5">
<Value>OriginalDate</Value>
</Value>
<Value name="6">
<Value>OriginalText</Value>
</Value>
</Data>
<DefaultData>ReceiptRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

