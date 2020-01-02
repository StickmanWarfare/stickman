unit AbstractFegyv;

interface
  uses SysUtils, windows, typestuff, math, Direct3d9, d3dx9;

const
  //FILE STRUCTURE
  FEGYV_PATH = 'data/models/weapons';
  SKINS_PATH = 'data/textures/weapons/skins';
  MESH_EXT = '.x';
  TEXTURE_EXT = '.jpg';
  //
  //WEAPON FILE NAMES
  F_M4A1 = 'm4a1';
  F_M82A1 = 'm82';
  F_LAW = 'law';
  F_MP5A3 = 'mp5';
  F_BM3 = 'bm3';
  //
  F_MPG = 'mpg';
  F_QUADRO = 'quad';
  F_NOOB = 'noob';
  F_X72 = 'x72';
  F_HPL = 'hpl';
  //
  F_H31 = 'h31';
  //
  //SKIN FOLDER NAMES
  F_SKIN_DEFAULT = 'default';
  F_SKIN_GOLDEN = 'golden';
  F_SKIN_XMAS = 'xmas';
  F_SKIN_BLUE = 'blue';
  //
  //MISC GLOBALS
  FEGYV_LOAD_FAIL_MSG = 'Failed to load fegyv: ';

type
  muzzRange = 0..17;
  smallMuzzRange = 0..5;
  scalRange = 0..11;

  TFegyvName = (
    FEGYV_NAME_M4A1 = 0,
    FEGYV_NAME_M82A1 = 1,
    FEGYV_NAME_LAW = 2,
    FEGYV_NAME_MP5A3 = 3,
    FEGYV_NAME_BM3 = 4,
    //
    FEGYV_NAME_MPG = 5,
    FEGYV_NAME_QUADRO = 6,
    FEGYV_NAME_NOOB = 7,
    FEGYV_NAME_X72 = 8,
    FEGYV_NAME_HPL = 9,
    //
    FEGYV_NAME_H31 = 10
  );

  TSkinName = (
    SKIN_NAME_DEFAULT = 0,
    SKIN_NAME_GOLDEN = 1,
    SKIN_NAME_XMAS = 2,
    SKIN_NAME_BLUE = 3
  );

  //BASE CLASS
  TAbstractFegyv = class(TObject)
  protected
    g_pMesh: ID3DXMesh;
    g_pD3Ddevice: IDirect3ddevice9;
    muzz: array[muzzRange] of TCustomVertex;
    procedure makemuzzle; virtual; abstract;
    procedure makemuzzlequad(hol:integer;v1, v2, v3, v4:TCustomVertex);
  public           
    skin: IDirect3DTexture9;
    betoltve:boolean;
    fc:single;
    muzzez:array of TCustomvertex;
    procedure draw;
    procedure pluszmuzzmatr(siz:single); virtual; abstract;
    procedure drawmuzzle(siz:single); virtual; abstract;
    constructor Create(a_D3Ddevice:IDirect3ddevice9;fnev:string;ftex:string);
    destructor Destroy; reintroduce;
  end;

  //KISMUZZ
  TAbstractSmallMuzzFegyv = class(TAbstractFegyv)
  protected
    muzz: array[smallMuzzRange] of TCustomVertex;
  end;

  //SCOPED
  TAbstractScopeFegyv = class(TAbstractFegyv)
  protected
    scaltex: IDirect3DTexture9;
    scal: array[scalRange] of TSkyVertex;
    procedure makescalequad(hol:integer;m1, m2, m3, m4:TD3DXVector3); virtual; abstract;
  public
    procedure drawscope; virtual; abstract;
  end;

  //LIGHMAPPED
  TAbsctractEmittingFegyv = class(TAbstractFegyv)
  protected
    emap: IDirect3DTexture9;
  public
    procedure draw; reintroduce;
  end;

implementation
////////////////////////////////
//         ABSTRACT
///////////////////////////////
constructor TAbstractFegyv.Create(a_D3Ddevice:IDirect3ddevice9;fnev:string;ftex:string);
var
  tempmesh:ID3DXMesh;
  pVert:PCustomvertexarray;
  vmi, vma, tmp:TD3DVector;
  scl:single;
  i:integer;
  adj:PDword;
begin
  inherited Create;
  betoltve:=false;
  g_pD3Ddevice:=a_D3Ddevice;
  addfiletochecksum(FEGYV_PATH + '/' + fnev + MESH_EXT);

  if not LTFF(g_pd3dDevice, SKINS_PATH + '/' + ftex + '/' + fnev + TEXTURE_EXT, skin) then
    Exit;

  makemuzzle;

  if FAILED(D3DXLoadMeshFromX(PChar(FEGYV_PATH + '/' + fnev + MESH_EXT), 0, g_pd3ddevice, nil, nil, nil, nil, tempmesh)) then exit;
  if FAILED(tempmesh.CloneMeshFVF(0, D3DFVF_CUSTOMVERTEX, g_pd3ddevice, g_pMesh)) then exit;
  if tempmesh <> nil then tempmesh:=nil;
  g_pMesh.LockVertexBuffer(0, pointer(pvert));
  D3DXComputeboundingbox(pointer(pvert), g_pMesh.GetNumVertices, g_pMesh.GetNumBytesPerVertex, vmi, vma);
  scl:=max(vma.x - vmi.x, max(vma.y - vmi.y, vma.z - vmi.z));
  scl:=scl / 0.7;
  fc:=(vma.z - vmi.z) * 0.5;
  for i:=0 to g_pMesh.GetNumVertices - 1 do
  begin
    tmp.z:= -(pvert[i].position.x - vmi.x) / scl - 0.04;
    tmp.y:=(pvert[i].position.y - vma.y) / scl + 0.001;
    tmp.x:=(pvert[i].position.z - vma.z + fc) / scl;
    //if abs(tmp.x)<0.005 then tmp.x:=0;
    pvert[i].color:=RGB(200, 200, 200);
    pvert[i].position:=tmp;
  end;
  g_pMesh.UnlockVertexBuffer;
  getmem(adj, g_pmesh.getnumfaces * 12);
  g_pMesh.generateadjacency(0.001, adj);
  D3DXComputenormals(g_pMesh, nil);
  g_pMesh.OptimizeInplace(D3DXMESHOPT_COMPACT + D3DXMESHOPT_ATTRSORT + D3DXMESHOPT_VERTEXCACHE, adj, nil, nil, nil);
  freemem(adj);
  betoltve:=true;
end;

procedure TAbstractFegyv.makemuzzlequad(hol:integer;v1, v2, v3, v4:TCustomVertex);
begin
  muzz[hol + 0]:=v1;
  muzz[hol + 1]:=v2;
  muzz[hol + 2]:=v3;
  muzz[hol + 3]:=v4;
  muzz[hol + 4]:=v2;
  muzz[hol + 5]:=v3;
end;

procedure TAbstractFegyv.draw;
begin
  g_pd3dDevice.Settexture(0, skin);
  g_pMesh.DrawSubset(0);
end;

procedure TAbsctractEmittingFegyv.draw;
begin
  g_pd3dDevice.SetTextureStageState(1, D3DTSS_COLORARG1, D3DTA_TEXTURE);
  g_pd3dDevice.SetTextureStageState(1, D3DTSS_COLORARG2, D3DTA_CURRENT);
  g_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_ADD);
  g_pd3dDevice.Settexture(0, skin);
  g_pd3dDevice.Settexture(1, emap);
  g_pMesh.DrawSubset(0);

  g_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE);
end;

destructor TAbstractFegyv.Destroy;
begin
  if skin <> nil then
    skin:=nil;
  if g_pmesh <> nil then
    g_pmesh:=nil;
  if g_pd3ddevice <> nil then
    g_pd3ddevice:=nil;
end;

end.
 