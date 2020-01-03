unit h31;

interface   
  uses AbstractFegyv, typestuff, Direct3d9, d3dx9, Math, windows;

type TF_H31 = class(TAbstractFegyv)
  protected
    procedure setupMesh; override;
  public
    procedure pluszmuzzmatr(siz:single); override;
  end;

implementation

procedure TF_H31.setupMesh;
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
    tmp.z:= -(pvert[i].position.x - vmi.x) * 1.5 / scl + 0.2;
    tmp.y:=(pvert[i].position.y - vma.y) / scl + 0.03;
    tmp.x:=(pvert[i].position.z - vma.z + fc) / scl - 0.084;
    //  if abs(tmp.x)<0.005 then tmp.x:=0;
    pvert[i].color:=RGB(200, 200, 200);
    pvert[i].position:=tmp;
  end;
  g_pMesh.UnlockVertexBuffer;
end;

procedure TF_H31.pluszmuzzmatr(siz:single);
var
  matWorld, matWorld2:TD3DMatrix;
begin

  D3DXMatrixTranslation(matWorld, -0.00, -0.08, -0.7);
  D3DXMatrixScaling(matWorld2, siz, siz, siz);
  D3DXmatrixMultiply(matWorld, matWorld2, MatWorld);
  g_pd3dDevice.MultiplyTransform(D3DTS_WORLD, matWorld);

end;

end.
