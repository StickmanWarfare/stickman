unit FegyvBuilder;

interface
  uses SysUtils, windows, Direct3d9, AbstractFegyv,
  m4a1, m82a1, law, mp5a3, bm3,
  mpg, quadro, noob, x72, hpl,
  h31;

type TFegyvFactory = class(TObject)
  private
    d3ddevice: IDirect3ddevice9;
    skin: TSkinName;
  public
    M4A1: TF_M4A1;
    M82A1: TF_M82A1;
    LAW: TF_LAW;
    MP5A3: TF_MP5A3;
    BM3: TF_BM3;

    MPG: TF_MPG;
    QUADRO: TF_QUADRO;
    NOOB: TF_NOOB;
    X72: TF_X72;
    HPL: TF_HPL;

    H31: TF_H31;

    constructor Create(_d3ddevice: IDirect3ddevice9);
    procedure setSkin(_skin: TSkinName);
    procedure make;
  end;

implementation

////////////////////////////////
//          HELPERS
///////////////////////////////
function getFegyvFileName(name: TFegyvName): string;
begin
  case name of
    FEGYV_NAME_M4A1: result := F_M4A1;
    FEGYV_NAME_M82A1: result := F_M82A1;
    FEGYV_NAME_LAW: result := F_LAW;
    FEGYV_NAME_MP5A3: result := F_MP5A3;
    FEGYV_NAME_BM3: result := F_BM3;
    //
    FEGYV_NAME_MPG: result := F_MPG;
    FEGYV_NAME_QUADRO: result := F_QUADRO;
    FEGYV_NAME_NOOB: result := F_NOOB;
    FEGYV_NAME_X72: result := F_X72;
    FEGYV_NAME_HPL: result := F_HPL;
    //
    FEGYV_NAME_H31: result := F_H31;
  end;
end;

function getSkinFolderName(name: TSkinName): string;
begin
  case name of
    SKIN_NAME_DEFAULT: result := F_SKIN_DEFAULT;
    SKIN_NAME_GOLDEN: result := F_SKIN_GOLDEN;
    SKIN_NAME_XMAS: result := F_SKIN_XMAS;
    SKIN_NAME_BLUE: result := F_SKIN_BLUE;
  end;
end;


////////////////////////////////
//          FACTORY
///////////////////////////////
constructor TFegyvFactory.Create(_d3ddevice: IDirect3ddevice9);
begin
  d3ddevice := _d3ddevice;
  skin := SKIN_NAME_DEFAULT;
end;

procedure TFegyvFactory.setSkin(_skin: TSkinName);
begin
  skin := _skin;
end;

procedure TFegyvFactory.make;
var
  ftex: string;
begin
  ftex := getSkinFolderName(skin);

  M4A1 := TF_M4A1.Create(d3ddevice, F_M4A1, ftex);
  if not M4A1.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_M4A1 + ' with ' + ftex);

  M82A1 := TF_M82A1.Create(d3ddevice, F_M82A1, ftex);
  if not M82A1.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_M82A1 + ' with ' + ftex);

  MP5A3 := TF_MP5A3.Create(d3ddevice, F_MP5A3, ftex);
  if not MP5A3.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_MP5A3 + ' with ' + ftex);

  LAW := TF_LAW.Create(d3ddevice, F_LAW, ftex);
  if not LAW.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_LAW + ' with ' + ftex);

  BM3 := TF_BM3.Create(d3ddevice, F_BM3, ftex);
  if not BM3.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_BM3 + ' with ' + ftex);


  MPG := TF_MPG.Create(d3ddevice, F_MPG, ftex);
  if not MPG.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_MPG + ' with ' + ftex);

  QUADRO := TF_QUADRO.Create(d3ddevice, F_QUADRO, ftex);
  if not QUADRO.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_QUADRO + ' with ' + ftex);

  NOOB := TF_NOOB.Create(d3ddevice, F_NOOB, ftex);
  if not NOOB.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_NOOB + ' with ' + ftex);

  X72 := TF_X72.Create(d3ddevice, F_X72, ftex);
  if not X72.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_X72 + ' with ' + ftex);

  HPL := TF_HPL.Create(d3ddevice, F_HPL, ftex);
  if not HPL.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_HPL + ' with ' + ftex);

  H31 := TF_H31.Create(d3ddevice, F_H31, getSkinFolderName(SKIN_NAME_XMAS));//FIXME
  if not H31.betoltve then
    raise Exception.Create(FEGYV_LOAD_FAIL_MSG + F_H31 + ' with ' + getSkinFolderName(SKIN_NAME_XMAS));//FIXME
end;

end.
