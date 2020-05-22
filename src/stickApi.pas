unit stickApi;

interface

uses
 Classes,
 Windows,
 SysUtils,
 multiplayer,
 qjson,
 IdHTTP;

const baseUrl = 'https://stickman.hu/api?mode=';    

//TODO: remove
type TAsync = class(TThread)
end;

type TApiResponse = record
  success: boolean;
  data: TQJSON;
end;

type TApi = class(TObject)
private
public
   function GET(const url: string): TApiResponse;
end;

implementation

{
  HELPER FUNCTIONS
}
function StreamToString(Stream: TMemoryStream): String;
var
    len: Integer;
begin
    len := Stream.Size - Stream.Position;
    SetLength(Result, len);
    if len > 0 then Stream.ReadBuffer(Result[1], len);
end;

{
  TApi
}
function TApi.GET(const url: string): TApiResponse;
begin
  try
    result.success := true;
    result.data := TQJSON.CreateFromHTTP(url);
  except
    result.success := false;
    result.data := TQJSON.Create;
  end;
end;

end.

