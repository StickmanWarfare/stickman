unit ThreadHandler;

interface

  uses
    Classes,
    Variants,
    //
    Typestuff,
    QJSON;

  type TSaga = class (TObject)
    private
      _key: string;
      _callback: TIndefiniteProcedure;
    published
      constructor Create(key: string; callback: TIndefiniteProcedure);
      function key: string;
      function callback: TIndefiniteProcedure; //this will be the thread execute
  end;

  type TCallbackThread = class (TThread)
    private
      _callback: TIndefiniteProcedure;
    protected
      procedure Execute(const args: array of const); reintroduce;
    published
      constructor Create(callback: TIndefiniteProcedure);
  end;

  TCallbackThreadArray = array of TCallbackThread;

  //TODO: proxy layer to takeLeading, takeLatest, etc sagas
  type TThreadHandler = class (TObject)
    private
      _sagas: array of TSaga;
      _threads: TCallbackThreadArray;
      procedure cleanup(hard: boolean = false);
    published
      constructor Create;
      procedure addSaga(saga: TSaga);
      function call(key: string; const args: array of const): THandle;  //creates new saga, suspended ones stay as-is
      //TODO: procedure all(keys: array of string; parallel: boolean = false);
      //TODO: procedure race(keys: array of string);
      //TODO: execute(key / keys / null)  //starts suspended ones, does not create new saga
      //TODO: suspend(key / keys / null)
      //TODO: terminate(key / keys / null)
      //TODO: waitFor(key / keys / null) //runs given saga(s), all others stay as-is/suspended
  end;


var
  threadHandlerModule: TThreadHandler;
  fastinfoSaga, printTopSaga, printRankSaga, printKothSaga, reportBotKillsSaga: TSaga; //TODO: move these
  

implementation

//TCallbackThread
constructor TCallbackThread.Create(callback: TIndefiniteProcedure);
begin
  inherited Create(true); //suspended on create

  _callback := callback;
end;

procedure TCallbackThread.Execute(const args: array of const);
begin
  _callback(args);
  terminate;
end;


//TSaga
constructor TSaga.Create(key: string; callback: TIndefiniteProcedure);
begin
  _key := key;
  _callback := callback;
end;

function TSaga.key: string;
begin
  result := _key;
end;

function TSaga.callback: TIndefiniteProcedure;
begin
  result := _callback;
end;


//TThreadHandler
constructor TThreadHandler.Create;
begin
  setlength(_sagas, 0);
  setlength(_threads, 0);
end;

procedure TThreadHandler.addSaga(saga: TSaga);
begin
  setlength(_sagas, succ(length(_sagas)));
  _sagas[high(_sagas)] := saga;
end;

function TThreadHandler.call(key: string; const args: array of const): THandle;
var
  i: Integer;
  saga: TSaga;
begin
  cleanup;
  saga := nil;
  result := Null;

  //find the saga
  for i := low(_sagas) to high(_sagas) do
    if _sagas[i].key <> key then
      continue
    else
    begin
      saga := _sagas[i];
      break;
    end;

  if saga = nil then exit;

  //create thread
  setlength(_threads, succ(length(_threads)));
  _threads[high(_threads)] := TCallbackThread.Create(saga.callback());

  result := _threads[high(_threads)].ThreadID;

  //execute
  _threads[high(_threads)].Execute(args);
end;

//TODO: clear results for deleted threads
procedure TThreadHandler.cleanup(hard: boolean = false);
var
  i: Integer;
  newThreads: TCallbackThreadArray;
begin
  setlength(newThreads, 0);

  if hard then
    for i := low(_threads) to high(_threads) do
    begin
      if _threads[i].Terminated then continue;
      if not _threads[i].Suspended then _threads[i].Suspend;
      _threads[i].Terminate;
    end;

  for i := low(_threads) to high(_threads) do
  begin
    if not _threads[i].Terminated then
    begin
      setlength(newThreads, length(newThreads) + 1);
      newThreads[high(newThreads)] := _threads[i];
    end
    else
      _threads[i].Destroy;
  end;

  setlength(_threads, length(newThreads));
  _threads := copy(newThreads, low(newThreads), length(newThreads));
end;

end.
