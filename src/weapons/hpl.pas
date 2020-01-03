unit hpl;

interface
  uses AbstractFegyv, typestuff, Direct3d9, d3dx9, Math, windows;

type TF_HPL = class(TAbsctractScopeEmittingFegyv)
  protected
    procedure makemuzzle; override;
    procedure setupMesh; override;
 procedure makescalequad(hol:integer;m1, m2, m3, m4:TD3DXVector3); override;
  public
    procedure drawscope; override;
    procedure pluszmuzzmatr(siz:single); override;
    procedure drawmuzzle(siz:single); override;
  end;

implementation

procedure TF_HPL.setupMesh;
var
  pVert:PCustomvertexarray;
  vmi, vma, tmp:TD3DVector;
  scl:single;
  i:integer;
begin
  g_pMesh.LockVertexBuffer(0, pointer(pvert));
  D3DXComputeboundingbox(pointer(pvert), g_pMesh.GetNumVertices, g_pMesh.GetNumBytesPerVertex, vmi, vma);
  scl:=max(vma.x - vmi.x, max(vma.y - vmi.y, vma.z - vmi.z));
  scl:=1.2 * 0.9 / scl;
  //  scl:=0.08675; //1200 mm a modell és 1041 kéne legyen
  fc:=(vma.x - vmi.x) * 0.5;
  for i:=0 to g_pMesh.GetNumVertices - 1 do
  begin
    tmp.z:=(pvert[i].position.z - vmi.z) * scl - 1.0; //Z=hátra
    tmp.y:=(pvert[i].position.y - vma.y) * scl + 0.03;
    tmp.x:=(pvert[i].position.x - vma.x + fc) * scl;
    //if abs(tmp.x)<0.005 then tmp.x:=0;
    pvert[i].color:=RGB(200, 200, 200);
    pvert[i].position:=tmp;
  end;
  g_pMesh.UnlockVertexBuffer;
end;

 
procedure TF_HPL.makemuzzle;
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


  makescalequad(0, D3DXVector3(-0.02, 0.00003, -0.2), D3DXVector3(-0.02, -0.000025, -0.2),
    D3DXVector3(0.02, 0.00003, -0.2), D3DXVector3(0.02, -0.000025, -0.2));
  makescalequad(6, D3DXVector3(-0.00003, 0.02, -0.2), D3DXVector3(-0.000025, -0.02, -0.2),
    D3DXVector3(0.00003, 0.02, -0.2), D3DXVector3(0.000025, -0.02, -0.2));
end;

procedure TF_HPL.drawscope;
begin
  g_pd3dDevice.SetFVF(D3DFVF_SKYVERTEX);
  g_pd3ddevice.settexture(0, scaltex);
  g_pd3ddevice.settexture(1, scaltex);
  g_pd3ddevice.settexture(2, scaltex);
  //  g_pd3dDevice.SetRenderState(D3DRS_SRCBLEND,D3DBLEND_ONE);
  g_pd3ddevice.drawprimitiveUP(D3DPT_TRIANGLELIST, 4, scal, sizeof(Tskyvertex));
end;

procedure TF_HPL.makescalequad(hol:integer;m1, m2, m3, m4:TD3DXVector3);
var
  v1, v2, v3, v4:TSkyVertex;
const
  uvszorzo = 5;
begin
  v1.position:=m1;v2.position:=m2;v3.position:=m3;v4.position:=m4;
  v1.u:=v1.position.x * uvszorzo;v1.v:=v1.position.y * uvszorzo;
  v2.u:=v2.position.x * uvszorzo;v2.v:=v2.position.y * uvszorzo;
  v3.u:=v3.position.x * uvszorzo;v3.v:=v3.position.y * uvszorzo;
  v4.u:=v4.position.x * uvszorzo;v4.v:=v4.position.y * uvszorzo;
  //v5.u:=v5.position.x*uvszorzo; v5.v:=v5.position.y*uvszorzo;
  scal[hol + 0]:=v1;
  scal[hol + 1]:=v2;
  scal[hol + 2]:=v3;
  scal[hol + 3]:=v3;
  scal[hol + 4]:=v2;
  scal[hol + 5]:=v4;
end;

procedure TF_HPL.pluszmuzzmatr(siz:single);
var
  matWorld, matWorld2:TD3DMatrix;
begin

  D3DXMatrixTranslation(matWorld, -0.00, -0.015, -0.89);
  D3DXMatrixScaling(matWorld2, siz / 2, siz / 2, siz);
  D3DXmatrixMultiply(matWorld, matWorld2, MatWorld);
  g_pd3dDevice.MultiplyTransform(D3DTS_WORLD, matWorld);

end;

procedure TF_HPL.drawmuzzle(siz:single);
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
