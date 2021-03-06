unit Selfie;

interface

uses
  Math,
  D3DX9,
  Direct3D9,
  Typestuff,
  muksoka;


type TSelfie = class
public
  isSelfieModeOn: boolean;
  zoomlevel: single;
  zoomlevelMax: single;
  zoomlevelMin: single;
  dab: boolean;
  muks: TMuksoka;
  fejcuccrenderer: TFejcuccrenderer;
  fegyv: BYTE;
  fejcucc: Integer;
  campos: TD3DXVector3;
  camrotX: single;
  camrotY: single;
  constructor Create(
    _muks: TMuksoka;
    _fegyv: BYTE;
    _fejcucc: Integer;
    _campos: TD3DXVector3;
    _camrotX: single;
    _camrotY: single
  );
  procedure render;
  procedure toggle;
end;

implementation


constructor TSelfie.Create(
  _muks: TMuksoka;
  _fegyv: BYTE;
  _fejcucc: Integer;
  _campos: TD3DXVector3;
  _camrotX: single;
  _camrotY: single
);
begin
  isSelfieModeOn := FALSE;
  dab := FALSE;
  zoomlevelMax := 5;
  zoomlevelMin:= 1.7;
  zoomlevel := zoomlevelMin;
  muks := _muks;
  fegyv := _fegyv;
  fejcucc := _fejcucc;
  campos := _campos;
  camrotX := _camrotX;
  camrotY := _camrotY;
end;

procedure TSelfie.render;
var
  szin: Cardinal;
  matWorld, matWorld2, matb: TD3DMatrix;
begin
  if not isSelfieModeOn then exit;

  if fegyv < 128 then szin := gunszin else szin := techszin;
  D3DXMatrixRotationY(matWorld2, camrotX); //+PI -PI lel
  if zoomlevel = zoomlevelMin then begin
    D3DXMatrixRotationX(matb, -camrotY*0.75);
  end else
    D3DXMatrixRotationX(matb, -camrotY*0.5);
  D3DXMatrixMultiply(matb, matb, matWorld2);
  D3DXMatrixTranslation(matWorld, campos.x, campos.y, campos.z);
  D3DXMatrixMultiply(matWorld2, matWorld2, matWorld);
  D3DXMatrixTranslation(matWorld, campos.x, campos.y, campos.z);
  D3DXMatrixMultiply(matb, matb, matWorld);

  if dab then
  begin
    //jobb konyok fejbe aztan ki
    muks.gmbk[6] := muks.gmbk[10];
    muks.gmbk[6].x := muks.gmbk[6].x - 0.2;

    //jobb kezfej fejbe aztan ki es fel
    muks.gmbk[8] := muks.gmbk[10];
    muks.gmbk[8].x := muks.gmbk[8].x - 0.4;
    muks.gmbk[8].y := muks.gmbk[8].y + 0.2;

    //bal konyok fejbe aztan elore es masik ki es le
    muks.gmbk[7] := muks.gmbk[10];
    muks.gmbk[7].x := muks.gmbk[7].x + 0.12;
    muks.gmbk[7].y := muks.gmbk[7].y - 0.1;
    muks.gmbk[7].z := muks.gmbk[7].z - 0.4;

    //bal kezfej fejbe aztan elore es ki es fel
    muks.gmbk[9] := muks.gmbk[10];
    muks.gmbk[9].x := muks.gmbk[9].x - 0.08;
    muks.gmbk[9].y := muks.gmbk[9].y + 0.08;
    muks.gmbk[9].z := muks.gmbk[9].z - 0.4;
  end
  else
  begin
    //if zoomlevel = zoomlevelMin then //fogom a kamerat
    //begin
      //arcomba rakom a kezem
     // muks.gmbk[8] := campos;
      //muks.gmbk[8].y := muks.gmbk[8].y + 0.2;

      //jobb konyok kicsit kamera fele
      //muks.gmbk[6].x := muks.gmbk[6].x - 0.2;
      //muks.gmbk[6].y := muks.gmbk[6].y + 0.1;
      //muks.gmbk[6].z := muks.gmbk[6].z - 0.2;
    //end
    //else
    //begin
      //jobb kezfej testem melle es le
      muks.gmbk[8].x := muks.gmbk[8].x - 0.1;
      muks.gmbk[8].y := muks.gmbk[8].y - 0.1;
      muks.gmbk[8].z := muks.gmbk[8].z + 0.2;
      
      //jobb konyok testem melle
      muks.gmbk[6].x := muks.gmbk[6].x - 0.1;
      muks.gmbk[6].z := muks.gmbk[6].z + 0.2;
    //end;

    //bal konyok testem melle es fel
    muks.gmbk[7].x := muks.gmbk[7].x + 0.2;
    muks.gmbk[7].y := muks.gmbk[7].y + 0.2;
    muks.gmbk[7].z := muks.gmbk[7].z + 0.2;

    //bal kezfej testem melle es fel
    muks.gmbk[9].x := muks.gmbk[9].x + 0.3;
    muks.gmbk[9].y := muks.gmbk[9].y + 0.4;
    muks.gmbk[9].z := muks.gmbk[9].z + 0.2;
  end;


  muks.Render(szin, matWorld2, campos);

  //fejcucc modifier
  matb._41 := matb._41 + muks.gmbk[10].x;
  matb._42 := matb._42 + muks.gmbk[10].y;
  matb._43 := matb._43 + muks.gmbk[10].z;
  fejcuccrenderer.render(fejcucc, matb, false, campos);
end;


procedure TSelfie.toggle;
begin
  isSelfieModeOn := not isSelfieModeOn;
end;

end.
