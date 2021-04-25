unit DynamicArray;

interface
  uses
    SysUtils,
    //
    Typestuff;

  type TVariantArray = array of Variant;

  type TDynamicArray = class (TObject)
    private
      _items: TVariantArray;
      _isFrozen: boolean;
      _isPermaFrozen: boolean;
    public
      constructor Create(); overload;
      constructor Create(items: TVariantArray); overload;
      procedure init;
      //
      function push(item: Variant): Integer; //index 
      function pop: Variant;
      function items: TVariantArray;
      function at(index: Integer): Variant;
      function head: Variant;
      function tail: TVariantArray;
      function size: Integer;    
      function isEmpty: boolean;
      function isFrozen: boolean;
      function isPermaFrozen: boolean;
      function find(comparator: TComparatorFunction): Variant;
      function findIndex(comparator: TComparatorFunction): Integer;
      function difference(other: TDynamicArray): TDynamicArray;
      procedure clear;
      procedure map(mutator: TMutatorFunction);
      procedure merge(other: TDynamicArray);
      procedure freeze(isPermanent: boolean = false);
      procedure unFreeze;
      function toJSON(): string;
  end;

implementation

procedure TDynamicArray.init;
begin
  setlength(_items, 0);
  _isFrozen := false;
  _isPermaFrozen := false;
end;

constructor TDynamicArray.Create;
begin
  inherited Create;

  init;
end;

constructor TDynamicArray.Create(items: TVariantArray);
begin
  inherited Create;

  init;

  setlength(_items, length(items));
  _items := copy(items, low(items), length(items));
end;

function TDynamicArray.push(item: Variant): Integer; //index
begin
  result := -1;

  if _isFrozen or _isPermaFrozen then exit;

  setlength(_items, succ(length(_items)));
  _items[high(_items)] := item;

  result := high(_items);
end;

function TDynamicArray.pop: Variant;
begin
  if _isFrozen or _isPermaFrozen then exit;

  if length(_items) <= 0 then exit;

  result := _items[high(_items)];
  setlength(_items, pred(length(_items)));
end;

function TDynamicArray.items: TVariantArray;
begin
  result := _items;
end;

function TDynamicArray.at(index: Integer): Variant;
begin
  if length(_items) <= 0 then exit;
  if index >= length(_items) then exit;
  if index <= 0 then exit;

  result := _items[index];
end;

function TDynamicArray.head: Variant;
begin
  if length(_items) <= 0 then exit;

  result := _items[low(_items)];
end;

function TDynamicArray.tail: TVariantArray;
begin
  if length(_items) <= 1 then exit;

  result := copy(_items, 1, length(_items) - 1);
end;

function TDynamicArray.size: Integer;
begin
  result := length(_items);
end;

function TDynamicArray.isEmpty: boolean;
begin
  result := length(_items) <= 0;
end;

function TDynamicArray.isFrozen: boolean;
begin
  result := _isFrozen = true;
end;

function TDynamicArray.isPermaFrozen: boolean;
begin
  result := _isPermaFrozen = true;
end;

function TDynamicArray.find(comparator: TComparatorFunction): Variant;
var
  i: Integer;
begin
  if length(_items) <= 1 then exit;

  for i := low(_items) to high(_items) do
  begin
    if comparator(_items[i], intToStr(i)) then
    begin
      result := _items[i];
      exit;
    end;
  end;

end;

function TDynamicArray.findIndex(comparator: TComparatorFunction): Integer;
var
  i: Integer;
begin
  if length(_items) <= 1 then result := -1;

  for i := low(_items) to high(_items) do
  begin
    if comparator(_items[i], intToStr(i)) then
    begin
      result := i;
      exit;
    end;
  end;

end;

function TDynamicArray.difference(other: TDynamicArray): TDynamicArray;
begin
  result := TDynamicArray.Create;
  
  if length(_items) <= 1 then exit;

  //TODO: return items in self but not in other
end;

procedure TDynamicArray.clear;
begin
  if _isFrozen or _isPermaFrozen then exit;

  setlength(_items, 0);
end;

procedure TDynamicArray.map(mutator: TMutatorFunction);
var
  i: Integer;
begin
  if _isFrozen or _isPermaFrozen then exit;

  for i := low(_items) to high(_items) do
    _items[i] := mutator(_items[i], intToStr(i));

end;

procedure TDynamicArray.merge(other: TDynamicArray);
begin
  if _isFrozen or _isPermaFrozen then exit;

  //TODO: append items to end
end;

procedure TDynamicArray.freeze(isPermanent: boolean = false);
begin
  _isFrozen := true;
  _isPermaFrozen := _isPermaFrozen or isPermanent;
end;

procedure TDynamicArray.unFreeze;
begin
  if _isPermaFrozen then exit;

  _isFrozen := false;
end;

function TDynamicArray.toJSON(): string; 
var
  i: Integer;
begin
  result := '[';

  for i := low(_items) to high(_items) do
  begin
    if i > low(_items) then result := result + ', ';

    result := result + variantToStr(_items[i]);
  end;

  result := result + ']';
end;

end.
