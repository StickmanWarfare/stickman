unit MutableObject;

interface

  uses Typestuff, SysUtils;

    type TKeyValuePair = record
      key: string;
      value: Variant;
    end;

    //TODO: TImmutableObject

    type TMutableObject = class (TObject)
      private
        __values: array of TKeyValuePair;
        __isFrozen: boolean;
        __isPermaFrozen: boolean;
      public
        function assign(key: string; value: Variant; strict: boolean = false): Variant;
        function unset(key: string; strict: boolean = false): Variant;
        function get(key: string; strict: boolean = false): Variant;
        function size(): Cardinal;
        function has(value: Variant): boolean; overload;
        function has(key: string): boolean; overload;
        function keys(): TStringArray;
        function find(comparator: TComparatorFunction): Variant;
        function findKey(comparator: TComparatorFunction): string;
        function isEmpty(): boolean;
        function isFrozen(): boolean;
        function isPermaFrozen(): boolean;
        function difference(other: TMutableObject): TMutableObject;
        procedure clear();
        procedure freeze(isPermanent: boolean = false);
        procedure unFreeze();
        procedure merge(other: TMutableObject); overload;
        procedure merge(others: array of TMutableObject); overload;
        constructor Create(freeze: boolean = false);
    end;

implementation

constructor TMutableObject.Create(freeze: boolean = false);
begin
  inherited Create();

  setlength(__values, 0);
  __isFrozen := freeze;
end;

function TMutableObject.size(): Cardinal;
begin
  result := length(__values);
end;

function TMutableObject.isEmpty(): boolean;
begin
  result := size() = 0;
end;

function TMutableObject.isFrozen(): boolean;
begin
  result := __isFrozen = true;
end;

function TMutableObject.isPermaFrozen(): boolean;
begin
  result := __isPermaFrozen = true;
end;

function TMutableObject.find(comparator: TComparatorFunction): Variant;
var
  i: Integer;
begin
  for i := 0 to high(__values) do
  begin
    if comparator(__values[i].value, __values[i].key) then
    begin
      result := __values[i].value;
      exit;
    end;
  end;
end;

function TMutableObject.findKey(comparator: TComparatorFunction): string;
var
  i: Integer;
begin
  for i := 0 to high(__values) do
  begin
    if comparator(__values[i].value, __values[i].key) then
    begin
      result := __values[i].key;
      exit;
    end;
  end;
end;

function TMutableObject.has(value: Variant): boolean;
var
  i: Integer;
begin
  result := false;
  for i := 0 to high(__values) do
  begin
    if __values[i].value = value then
    begin
      result := true;
      exit;
    end;
  end;
end;

function TMutableObject.has(key: string): boolean;
var
  i: Integer;
begin
  result := false;
  for i := 0 to high(__values) do
  begin
    if __values[i].key = key then
    begin
      result := true;
      exit;
    end;
  end;
end;

function TMutableObject.assign(key: string; value: Variant; strict: boolean = false): Variant;
var
  i: Integer;
  newPair: TKeyValuePair;
begin
  if isFrozen() then exit;

  if not has(key) then
  begin
    if strict then
      raise Exception.Create('Invalid key: ' + key);

    newPair.key := key;
    newPair.value := value;

    setlength(__values, size() + 1);
    __values[high(__values)] := newPair;

    exit;
  end;

  for i := 0 to high(__values) do
  begin
    if __values[i].key = key then
    begin
      __values[i].value := value;
      exit;
    end;
  end;

end;

function TMutableObject.unset(key: string; strict: boolean = false): Variant;
var
  hasKey: boolean;
  i: Integer;
  found: boolean;
begin
  if isFrozen() then exit;

  if not has(key) then
  begin
    if strict then
      raise Exception.Create('Invalid key: ' + key);

    exit;
  end;

  for i := 0 to high(__values) do
  begin
    if __values[i].key = key then
    begin
      if found then
      begin
        if i = high(__values) then
          break;

        __values[i] := __values[i + 1];
      end
      else
      begin
        found := __values[i].key = key;
      end;
    end;
  end;

  setlength(__values, size() - 1);

end;

function TMutableObject.get(key: string; strict: boolean = false): Variant;
var
  i: Integer;
begin
  if not has(key) then
  begin
    if strict then
      raise Exception.Create('Invalid key: ' + key);

    exit;
  end;

  for i := 0 to high(__values) do
  begin
    if __values[i].key = key then
    begin
      result := __values[i].value;
      exit;
    end;
  end;
end;

function TMutableObject.keys(): TStringArray;
var
  i: Integer;
begin
  setlength(result, 0);

  for i := 0 to high(__values) do
  begin
    setlength(result, length(result) + 1);
    result[high(result)] := __values[i].key;
  end;
end;

//TODO: make overloaded version with others: array of TMutableObject
function TMutableObject.difference(other: TMutableObject): TMutableObject;
var
  i: Integer;
begin
  result := TMutableObject.Create();

  //TODO: return new TMutableObject with keys in self but not it other
end;

procedure TMutableObject.clear();
begin
  if isFrozen() then exit;
  setlength(__values, 0);
end;

procedure TMutableObject.freeze(isPermanent: boolean = false);
begin
  __isFrozen := true;
  __isPermaFrozen := __isPermaFrozen or isPermanent;
end;

procedure TMutableObject.unFreeze();
begin
  if isPermaFrozen() then exit;

  __isFrozen := false;
end;

procedure TMutableObject.merge(other: TMutableObject);
var
  i: Integer;
  newKeys: TStringArray;
begin
  for i := 0 to high(other.keys()) do
  begin
    if not has(other.keys()[i]) then
    begin
      assign(other.keys()[i], other.get(other.keys()[i]));
    end;
  end;
end;

procedure TMutableObject.merge(others: array of TMutableObject);
var
  i: Integer;
begin
  for i := 0 to high(others) do merge(others[i]);
end;

end.


