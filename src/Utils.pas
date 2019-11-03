unit Utils;

interface
uses
  Sysutils,
  Typestuff,
  D3DX9,
  ojjektumok;

type
  D3DXVector3Polyfill = class
    public
    function isEqual(vec1: TD3DXVector3; vec2: TD3DxVector3): Boolean;
  end;

  ByteArrayUtils = class
    public
    function indexOf(arr: array of Byte; value: Byte): Integer;
  end;

  IntArrayUtils = class
    public
    function indexOf(arr: array of Integer; value: Integer): Integer;
  end;

  StringArrayUtils = class 
    public
    function indexOf(arr: array of string; value: string): Integer;
  end;

  type TPlayerArray = array of TPlayer;
  TPlayerArrayUtils = class
    public
    function isEqual(player1: TPlayer; player2: TPlayer): Boolean;
    function indexOf(arr: TPlayerArray; value: TPlayer): Integer;
    function findByName(arr: TPlayerArray; value: string): Integer;
    function findByProximity(arr: TPlayerArray; point: TD3DXVector3; radius: Single): Integer;
//TODO    function findByPos();
//TODO    function findByClan();
//TODO    function findByFegyv();
//TODO    function findByTeam();
//TODO    function findByKills();
//TODO    function findByZone();
//TODO    function findByVector3();
//TODO    function findByVector2(); //x and z
    procedure filterByFegyv(result: TPlayerArray; arr: TPlayerArray; fegyv: byte);
    procedure filterByClan(result: TPlayerArray; arr: TPlayerArray; clan: string);
    procedure filterByTeam(result: TPlayerArray; arr: TPlayerArray; team: string); //'gun' or 'tech'
    procedure filterByKills(result: TPlayerArray; arr: TPlayerArray; kills: Integer; method: string = 'GE');
    procedure filterByZone(result: TPlayerArray; arr: TPlayerArray; zone: string);
    procedure filterByProximity(result: TPlayerArray; arr: TPlayerArray; point: TD3DXVector3; radius: Single);
//TODO    procedure filterByVector3();
//TODO    procedure filterByVector2(); //x and z
  end;
  
  type TBuildingArray = array of T3DOjjektum;
  TBuildingArrayUtils = class
    public
          procedure make(result: TBuildingArray; source: array of T3DOjjektum);
          function isEqual(building1: T3DOjjektum; building2: T3DOjjektum): Boolean;
          function indexOf(arr: TBuildingArray; value: T3DOjjektum): Integer;
//TODO    function findByZone();
//TODO    function findByPlayer();
//TODO    function findByTeam();
//TODO    function findByClan();
          procedure filterByZone(result: TBuildingArray; arr: TBuildingArray; zone: string);
//TODO    procedure filterByTeam();
//TODO    procedure filterByClan();
  end;

  type TLovesArray = array of TLoves;
  TLovesArrayUtils = class
    public
//TODO    function isEqual();
//TODO    function indexOf();
//TODO    function findByPlayer();
//TODO    function findByFegyv();
//TODO    procedure filterByPlayer();
//TODO    procedure filterByFegyv();
  end;

implementation

//BYTE START
function ByteArrayUtils.indexOf(arr: array of Byte; value: Byte): Integer;
var
  i: Integer;
label skip;
begin
  result := -1;
  for i := 0 to high(arr) do
    if arr[i] = value then
    begin
     result := i;
     goto skip;
    end;
  skip:
end;

//INT START
function IntArrayUtils.indexOf(arr: array of Integer; value: Integer): Integer;
var
  i: Integer;
label skip;
begin
  result := -1;
  for i := 0 to high(arr) do
    if arr[i] = value then
    begin
     result := i;
     goto skip;
    end;
  skip:
end;

//STRING START
function StringArrayUtils.indexOf(arr: array of string; value: string): Integer;
var
  i: Integer;
label skip;
begin
  result := -1;
  for i := 0 to high(arr) do
    if arr[i] = value then
    begin
     result := i;
     goto skip;
    end;
  skip:
end;

//TBUILDING START
procedure TBuildingArrayUtils.make(result: TBuildingArray; source: array of T3DOjjektum);
var
  i: Integer;
begin
  setLength(result, length(source));
  for i := 0 to high(source) do
    result[i] := source[i];
end;

function TBuildingArrayUtils.isEqual(building1: T3DOjjektum; building2: T3DOjjektum): Boolean;
begin
  result := building1.filenev = building2.filenev;
end;

function TBuildingArrayUtils.indexOf(arr: TBuildingArray; value: T3DOjjektum): Integer;
var
  i: Integer;
  BU: TBuildingArrayUtils;
label skip;
begin
  BU := TBuildingArrayUtils.Create();
  result := -1;
  for i := 0 to high(arr) do
    if BU.isEqual(arr[i], value) then
    begin
     result := i;
     goto skip;
    end;
  skip:
end;

procedure TBuildingArrayUtils.filterByZone(result: TBuildingArray; arr: TBuildingArray; zone: string);
var
  len, i: Integer;
begin
  len := 0;
  setLength(result, len);

  for i:= 0 to high(ojjektumarr) do
    if ojjektumzone[i] = zone then
    begin
      setLength(result, len + 1);
      result[len] := ojjektumarr[i];
      len := len + 1;
    end;
end;

//TPLAYER START
function TPlayerArrayUtils.isEqual(player1: TPlayer; player2: TPlayer): Boolean;
var
  DX: D3DXVector3Polyfill;
begin
  DX := D3DXVector3Polyfill.Create();
  result := (player1.pls.nev = player2.pls.nev)
            AND (player1.pls.fegyv = player2.pls.fegyv)
            AND (DX.isEqual(player1.pos.pos, player2.pos.pos));
end;

function TPlayerArrayUtils.indexOf(arr: TPlayerArray; value: TPlayer): Integer;
var
  i: Integer;
  PU: TPlayerArrayUtils;
label skip;
begin
  PU := TPlayerArrayUtils.Create();
  result := -1;
  for i := 0 to high(arr) do
    if PU.isEqual(arr[i], value) then
    begin
     result := i;
     goto skip;
    end;
  skip:
end;

function TPlayerArrayUtils.findByName(arr: TPlayerArray; value: string): Integer;
var
  i: Integer;
label skip;
begin
  result := -1;
  for i := 0 to high(arr) do
    if arr[i].pls.nev = value then
    begin
     result := i;
     goto skip;
    end;
  skip:
end;

function TPlayerArrayUtils.findByProximity(arr: TPlayerArray; point: TD3DXVector3; radius: Single): Integer;
var
  i: Integer;
label skip;
begin
  result := -1;
  for i := 0 to high(arr) do
    if tavpointpointsq(arr[i].pos.pos, point) < sqr(radius) then
    begin
     result := i;
     goto skip;
    end;
  skip:
end;

procedure TPlayerArrayUtils.filterByFegyv(result: TPlayerArray; arr: TPlayerArray; fegyv: byte);
var
  len, i: Integer;
begin
  len := 0;
  setLength(result, len);
  for i := 0 to high(arr) do
    if arr[i].pls.fegyv = fegyv then
    begin
      setLength(result, len + 1);
      result[len] := arr[i];
      len := len + 1;
    end;
end;

procedure TPlayerArrayUtils.filterByClan(result: TPlayerArray; arr: TPlayerArray; clan: string);
var
  len, i: Integer;
begin
  len := 0;
  setLength(result, len);
  for i := 0 to high(arr) do
    if arr[i].pls.clan = clan then
    begin
      setLength(result, len + 1);
      result[len] := arr[i];
      len := len + 1;
    end;
end;

procedure TPlayerArrayUtils.filterByTeam(result: TPlayerArray; arr: TPlayerArray; team: string);
var
  len, i: Integer;
begin
  len := 0;
  setLength(result, len);
  for i := 0 to high(arr) do
    if
      ((team = 'gun') AND (arr[i].pls.fegyv >= 128))
      OR ((team = 'tech') AND (arr[i].pls.fegyv < 128))
    then
    begin
      setLength(result, len + 1);
      result[len] := arr[i];
      len := len + 1;
    end;
end;

procedure TPlayerArrayUtils.filterByKills(result: TPlayerArray; arr: TPlayerArray; kills: Integer; method: string = 'GE');
var
  len, i: Integer;
begin
  len := 0;
  setLength(result, len);
  for i := 0 to high(arr) do
    if
      ((method = 'GT') AND (arr[i].pls.kills > kills))
      OR ((method = 'GE') AND (arr[i].pls.kills >= kills))
      OR ((method = 'EQ') AND (arr[i].pls.kills = kills))
      OR ((method = 'LE') AND (arr[i].pls.kills <= kills))
      OR ((method = 'LT') AND (arr[i].pls.kills < kills))
    then
    begin
      setLength(result, len + 1);
      result[len] := arr[i];
      len := len + 1;
    end;
end;

procedure TPlayerArrayUtils.filterByProximity(result: TPlayerArray; arr: TPlayerArray; point: TD3DXVector3; radius: Single);
var
  len, i: Integer;
begin
  len := 0;
  setLength(result, len);
  for i := 0 to high(arr) do
    if tavpointpointsq(arr[i].pos.pos, point) < radius then
    begin
      setLength(result, len + 1);
      result[len] := arr[i];
      len := len + 1;
    end;
end;

procedure TPlayerArrayUtils.filterByZone(result: TPlayerArray; arr: TPlayerArray; zone: string);
var
  len, i, j, index, k: Integer;
  instancedOjjektumarr, ojjektumokInZone: TBuildingArray;
  BU: TBuildingArrayUtils;
label
  skip, bigskip;
begin
  BU := TBuildingArrayUtils.Create();
  BU.make(instancedOjjektumarr, ojjektumarr);
  BU.filterByZone(ojjektumokInZone, instancedOjjektumarr, zone);
  len := 0;
  setLength(result, len);

  if length(ojjektumokInZone) <= 0 then goto bigskip;

  for i := 0 to high(arr) do
    for j := 0 to high(ojjektumokInZone) do
    begin
      index := BU.indexOf(instancedOjjektumarr, ojjektumokInZone[i]);
      if index > -1 then
      begin
        for k := 0 to high(ojjektumhv[index]) do
        begin
          if tavpointpoint(arr[i].pos.pos, ojjektumhv[index][k]) <= instancedOjjektumarr[index].rad then
          begin
            setLength(result, len + 1);
            result[len] := arr[i];
            len := len + 1;
            goto skip;
          end;
        end;
      end;
      skip:
    end;

    bigskip:
end;

//D3DXVECTOR3 START
function D3DXVector3Polyfill.isEqual(vec1: TD3DXVector3; vec2: TD3DxVector3): Boolean;
begin
  result := (vec1.x = vec2.x)
            AND (vec1.y = vec2.y)
            AND (vec1.z = vec2.z)
end;

end.
