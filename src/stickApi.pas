unit stickApi;

interface

uses
 Classes,
 Windows,
 SysUtils,
 multiplayer,
 IdHTTP;

const baseUrl = 'http://stickman.hu/api?mode=';    

//TODO: remove
type TAsync = class(TThread)
end;

type TApiResponse = record
  success: boolean;
  data: string; //TODO: TQJSON;
end;

type TApi = class
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
var
  client: TIdHTTP;
  responseString: TMemoryStream;
begin
  try
    responseString := TMemoryStream.Create;
    client := TIdHTTP.Create(nil);
    client.HandleRedirects := TRUE;

//TODO: requires Indy10
//    Id_HandlerSocket := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
//    Id_HandlerSocket.SSLOptions.Mode := sslmClient;
//    Id_HandlerSocket.SSLOptions.Method := sslvTLSv1_2;
//    client.IOHandler := Id_HandlerSocket;
    
    client.Get(url, responseString);
    result.success := true;
    result.data := StreamToString(responseString);//TQJSON.CreateFromHTTP(url);
  except
    result.success := false;
    result.data := ''; //TQJSON.Create;
  end;

  client.Free;
end;

end.

