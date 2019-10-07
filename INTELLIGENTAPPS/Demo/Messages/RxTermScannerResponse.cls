Class Demo.Messages.RxTermScannerResponse Extends Ens.Response
{

Property Items As list Of RxTermScannerItem(XMLITEMNAME = "Item", XMLPROJECTION = "ELEMENT");

Storage Default
{
<Data name="RxTermScannerResponseDefaultData">
<Subscript>"RxTermScannerResponse"</Subscript>
<Value name="1">
<Value>Items</Value>
</Value>
</Data>
<DefaultData>RxTermScannerResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

