unit m4a1;

interface
  uses AbstractFegyv, typestuff, Direct3d9, d3dx9, Math, windows;

type TF_M4A1 = class(TAbstractFegyv)
  protected
    procedure makemuzzle; override;
    procedure setupMesh; override;
  public
    procedure pluszmuzzmatr(siz:single); override;
    procedure drawmuzzle(siz:single); override;
  end;

implementation

procedure TF_M4A1.setupMesh;
var
  pVert:PCustomvertexarray;
  vmi, vma, tmp:TD3DVector;
  scl:single;
  i:integer;
begin
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
end;


procedure TF_M4A1.makemuzzle;
begin
  makemuzzlequad(0, CustomVertex(-0.5, -0.5, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 0, 0, 0),
    CustomVertex(0.5, -0.5, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 2, 0, 0, 0),
    CustomVertex(-0.5, 0.5, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 2, 0, 0),
    CustomVertex(0.5, 0.5, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 2, 2, 0, 0));
  makemuzzlequad(6, CustomVertex(0, 0, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 0, 0, 0),
    CustomVertex(0, 0.5, -0.5, 0, 0, 0, ARGB(255, 255, 255, 255), 1, 0, 0, 0),
    CustomVertex(0, -0.5, -0.5, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 1, 0, 0),
    CustomVertex(0, 0, -1, 0, 0, 0, ARGB(255, 255, 255, 255), 1, 1, 0, 0));
  makemuzzlequad(12, CustomVertex(0, 0, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 0, 0, 0),
    CustomVertex(0.5, 0, -0.5, 0, 0, 0, ARGB(255, 255, 255, 255), 1, 0, 0, 0),
    CustomVertex(-0.5, 0, -0.5, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 1, 0, 0),
    CustomVertex(0, 0, -1, 0, 0, 0, ARGB(255, 255, 255, 255), 1, 1, 0, 0));

end;

procedure TF_M4A1.pluszmuzzmatr(siz:single);
var
  matWorld, matWorld2:TD3DMatrix;
begin

  D3DXMatrixTranslation(matWorld, -0.00, -0.06, -0.72);
  D3DXMatrixScaling(matWorld2, siz / 2, siz / 2, siz);
  D3DXmatrixMultiply(matWorld, matWorld2, MatWorld);
  g_pd3dDevice.MultiplyTransform(D3DTS_WORLD, matWorld);

end;

procedure TF_M4A1.drawmuzzle(siz:single);
var
  mat:TD3DMatrix;
  lngt, i:integer;
begin
  if siz = 0 then exit;

  pluszmuzzmatr(siz);

  g_pd3ddevice.GetTransform(D3DTS_WORLD, mat);
  lngt:=length(muzzez);
  setlength(muzzez, lngt + length(muzz));
  for i:=0 to high(muzz) do
  begin
    muzzez[i + lngt]:=muzz[i];
    D3DXVec3TransformCoord(muzzez[i + lngt].position, muzz[i].position, mat);
  end;
  // g_pd3ddevice.drawprimitiveUP(D3DPT_TRIANGLELIST,6,muzz,sizeof(TCustomvertex));
end;

end.
