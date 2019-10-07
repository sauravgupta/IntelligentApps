Class Demo.Messages.OCRRequest Extends Ens.Request
{

Property ImageData As %Stream.GlobalBinary;

Storage Default
{
<Data name="OCRRequestDefaultData">
<Subscript>"OCRRequest"</Subscript>
<Value name="1">
<Value>ImageData</Value>
</Value>
</Data>
<DefaultData>OCRRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

