Class Demo.Messages.RxTermScannerItem Extends (%SerialObject, %XML.Adaptor)
{

Property RxCode As %String(MAXLEN = 10);

Property DrugName As %String(MAXLEN = 3000);

Property SourceLine As %String(MAXLEN = 3000);

Property SourceToken As %String(MAXLEN = 1000);

Storage Default
{
<Data name="RxTermScannerItemState">
<Value name="1">
<Value>RxCUI</Value>
</Value>
<Value name="2">
<Value>DrugName</Value>
</Value>
<Value name="3">
<Value>SourceLine</Value>
</Value>
<Value name="4">
<Value>SourceToken</Value>
</Value>
<Value name="5">
<Value>RxCode</Value>
</Value>
</Data>
<State>RxTermScannerItemState</State>
<StreamLocation>^Demo.Messages.RxTermScann2986S</StreamLocation>
<Type>%Storage.Serial</Type>
}

}

