unit Utils;

interface
uses
  Sysutils,
  Typestuff,
  D3DX9,
  Direct3D9,
  ojjektumok,
  fizika,
  windows,
  qjson;

type
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

  type TRenderUtils = class (TObject)
    protected
      g_pD3Ddevice: IDirect3ddevice9;
    public
      constructor Create(d3dxDevice: IDirect3DDevice9);
      //TODO: procedure drawTextOnHud(text: string; pos: TD3DXVector2; color: Cardinal);
      //TODO: procedure drawText(text: string; pos: TD3DXVector2; color: Cardinal);
      procedure drawBox(pos: TD3DXVector3; size: TD3DXVector3; color: Cardinal);
      //TODO: procedure displayText(text: string);
  end;

  type TMapUtils = class (TObject)
    public
      function getMapHeight(xx, zz: Single): Single;
      function vanOttValami(xx:single;var yy:single;zz:single):boolean;
      function raytestlvl(v1, v2:TD3DXVector3; hany:integer; var v3:TD3DXVector3):boolean;
  end;

  type VariantUtils = class (TObject)
    published
      class function VarRecToStr(rec: TVarRec): string;
      //TODO: class function VarRecToInt(): string;
      //TODO: class function VarRecToFloat(): string;
    end;

  //TODO: remove
  type KillMeUtils = class (TObject)
    published
      class function unhungaryify(src: string): string;
  end;


implementation

class function KillMeUtils.unhungaryify(src: string): string;
begin
  result := src;
  result := StringReplace(result, 'á', 'a', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, 'é', 'e', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, 'í', 'i', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, 'ó', 'o', [rfReplaceAll, rfIgnoreCase]); 
  result := StringReplace(result, 'ö', 'o', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, 'o', 'o', [rfReplaceAll, rfIgnoreCase]); //ez egy hoszzu ö
  result := StringReplace(result, 'ú', 'u', [rfReplaceAll, rfIgnoreCase]); 
  result := StringReplace(result, 'ü', 'u', [rfReplaceAll, rfIgnoreCase]);
  result := StringReplace(result, 'u', 'u', [rfReplaceAll, rfIgnoreCase]); //emmeg hosszu ü
end;

class function VariantUtils.VarRecToStr(rec: TVarRec): string;
begin
  with rec do
    case VType of
      vtInteger:  Result := Result + IntToStr(VInteger);
      vtBoolean:  Result := Result + BoolToStr(VBoolean);
      vtChar:     Result := Result + VChar;
      vtExtended: Result := Result + FloatToStr(VExtended^);
      vtString:   Result := Result + string(VAnsiString);//VString^;
      vtPChar:    Result := Result + string(VAnsiString); //VPChar;
      vtObject:   Result := Result + VObject.ClassName;
      vtClass:    Result := Result + VClass.ClassName;
      vtAnsiString:  Result := Result + string(VAnsiString);
      //vtUnicodeString:  Result := Result + string(VUnicodeString);
      vtCurrency:    Result := Result + CurrToStr(VCurrency^);
      vtVariant:     Result := Result + string(VVariant^);
      vtInt64:       Result := Result + IntToStr(VInt64^);
    
  end;
end;
    
//MAP START
function TMapUtils.vanOttValami(xx:single;var yy:single;zz:single):boolean; //copy of vanottvalami
const
  szor = 2;
var
  i:integer;
  tav:single;
begin
  result:=false;

  for i:=0 to high(posrads) do
    with posrads[i] do
    begin

      tav:=sqr(posx - xx) + sqr(posz - zz);
      if tav > sqr(raddn) then continue;

      if tav < sqr(radd) then
        tav:=0
      else
      begin
        tav:=sqrt(tav);
        if tav<(radd + raddn) * 0.5 then
          tav:=sqr((tav - radd) / (raddn - radd)) * 2
        else
          tav:=1 - sqr((raddn - tav) / (raddn - radd)) * 2;
      end;
      yy:=posy * (1 - tav) + yy * tav;
      result:=true;
    end;
end;

function TMapUtils.raytestlvl(v1, v2:TD3DXVector3; hany:integer; var v3:TD3DXVector3):boolean; //copy of raytestlvl
var
  k:integer;
  v4:TD3DXVector3;
begin
  v4:=v1;
  for k:=0 to hany do
  begin
    v3:=v4;
    d3dxvec3lerp(v4, v1, v2, k / (hany + 1));
    try
      if getMapHeight(v4.x, v4.z) > v4.y then
      begin
        result:=true;exit;
        v3:=v4;
      end;
    except
      v3:=v2;result:=false;exit;
    end;
  end;

  result:=false;
end;

function TMapUtils.getMapHeight(xx, zz: Single): Single;
var
  ay:single;
begin
  if (xx < -10000) or (xx > 10000) or (zz < -10000) or (zz > 10000) then
  begin
    result:=0;
    exit;
  end;
  ay:=wove(xx, zz);
  vanOttValami(xx, ay, zz);
  result:=ay;
end;

//RENDER START
constructor TRenderUtils.Create(d3dxDevice: IDirect3DDevice9);
begin
  inherited Create;

  g_pD3Ddevice := d3dxDevice;
end;

procedure TRenderUtils.drawBox(pos: TD3DXVector3; size: TD3DXVector3; color: Cardinal);
var
  oo: HRESULT;
  mesh: ID3DXMesh;
  tempmesh:ID3DXMesh;
begin
  g_pd3dDevice.SetRenderState(D3DRS_FOGENABLE, itrue);

  g_pd3dDevice.SetTexture(0, nil);
  g_pd3dDevice.SetRenderState(D3DRS_FOGENABLE, iFalse);
  g_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iTrue);
  g_pd3dDevice.SetRenderState(D3DRS_AMBIENT, color);

  oo := D3DXCreateBox(g_pD3DDevice, size.x, size.y, size.z, tempmesh, nil);
  if (oo <> D3D_OK) then Exit;
  if tempmesh = nil then exit;
  if FAILED(tempmesh.CloneMeshFVF(0, D3DFVF_XYZ or D3DFVF_NORMAL, g_pd3ddevice, mesh)) then exit;
  if tempmesh <> nil then tempmesh:=nil;

  //normalizemesh(mesh);

  mat_world:=identmatr;
  mat_world._11:=1;
  mat_world._22:=1;
  mat_world._33:=1;
  mat_world._41:=pos.x;
  mat_world._42:=pos.y;
  mat_world._43:=pos.z;
  g_pd3dDevice.SetTransform(D3DTS_WORLD, mat_World);
  mesh.DrawSubset(0);
end;

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
begin
  result := (player1.pls.nev = player2.pls.nev)
            AND (player1.pls.fegyv = player2.pls.fegyv)
            AND (D3DXVector3Equal(player1.pos.pos, player2.pos.pos));
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
  setLength(instancedOjjektumarr, 0);
  setLength(ojjektumokInZone, 0);

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

end.

