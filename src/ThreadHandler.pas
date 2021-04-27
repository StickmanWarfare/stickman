unit ThreadHandler;

interface

  uses
    Classes,
    SysUtils,
    //
    Typestuff,
    QJSON,
    Sentry;

  type TSagaMode = (
        TAKE_LEADING, //leading debounce
        TAKE_LATEST,  //trailing debounce
        TAKE_EVERY
    );

  type TSaga = class (TObject)
    private
      _key: string;
      _mode: TSagaMode;
      _callback: TJSONProcedure;
    published
      constructor Create(key: string; mode: TSagaMode; callback: TJSONProcedure);
      property key: string read _key;
      property mode: TSagaMode read _mode;
      function callback: TJSONProcedure; //ez lesz a thread execute
  end;

  type TCallbackThread = class (TThread)
    private
      _sagaKey: string;
      _callback: TJSONProcedure;
      _callbackArgs: TQJSON;
      _finished: boolean;
    protected
      procedure Execute; override;
    published     
      property sagaKey: string read _sagaKey;
      property finished: boolean read _finished;
      constructor Create(sagaKey: string; callback: TJSONProcedure; args: TQJSON);
      procedure forceFinish;
  end;

  TCallbackThreadArray = array of TCallbackThread;
  PCallbackThreadArray = array of ^TCallbackThread;

  type TThreadHandler = class (TObject)
    private
      _sagas: array of TSaga;
      _threads: TCallbackThreadArray;
      procedure cleanup(hard: boolean = false);
    published
      constructor Create;
      procedure addSaga(saga: TSaga);
      function call(key: string; args: TQJSON): THandle;  //újat indít, suspend marad ahogy volt
      //TODO: procedure all(keys: array of string; parallel: boolean = false);
      //TODO: procedure race(keys: array of string);
      //TODO: execute(key / keys / null)  //csak ha van is suspended, nem indít újat
      //TODO: suspend(key / keys / null)
      //TODO: terminate(key / keys / null)
      //TODO: waitFor(key / keys / null) //az lemegy, többi suspended
  end;


var
  threadHandlerModule: TThreadHandler;
  fastinfoSaga, printTopSaga, printRankSaga, printKothSaga, handleBotsSaga: TSaga; //TODO: move these
  

implementation

//TCallbackThread
constructor TCallbackThread.Create(sagaKey: string; callback: TJSONProcedure; args: TQJSON);
begin
  inherited Create(true); //suspended on create

  _sagaKey := sagaKey;
  _callback := callback;
  _callbackArgs := args;
  _finished := false;

  FreeOnTerminate := false; //cleanup szedi ossze
end;

procedure TCallbackThread.Execute;
begin
  laststate := 'execute';
  _callback(_callbackArgs);
  _finished := true;
end;

procedure TCallbackThread.forceFinish;
begin 
  laststate := 'forceFinish';
  _finished := true;
end;


//TSaga
constructor TSaga.Create(key: string; mode: TSagaMode; callback: TJSONProcedure);
begin
  _key := key;
  _mode := mode;
  _callback := callback;
end;

function TSaga.callback: TJSONProcedure;
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

function TThreadHandler.call(key: string; args: TQJSON): THandle;
var
  i, threadIndex: Integer;
  saga: TSaga;
  foundSaga, foundThread: boolean;
begin
  //remove finished threads
  cleanup;

  //find the saga
  foundSaga := false;
  for i := low(_sagas) to high(_sagas) do
    if _sagas[i].key <> key then
      continue
    else
    begin
      saga := _sagas[i];
      foundSaga := true;
      break;
    end;

  //we don goofed
  if not foundSaga then
  begin
    sentryModule.addBreadcrumb(makeBreadcrumb('[TThreadHandler.call] No saga with key: ' + key)); //lehetne reportError is
    exit;
  end;

  //look for running thread
  foundThread := false;
  for i := low(_threads) to high(_threads) do
    if _threads[i].sagaKey <> key then
      continue
    else
    begin
      if _threads[i].Finished then continue;

      sentryModule.reportError(Exception.Create('found not terminated thread'), 'asd');
      
      threadIndex := i;
      foundThread := true;
      break;
    end;

  //handle proxying
  if foundThread then
  begin
    if saga.mode = TAKE_LEADING then exit;

    if saga.mode = TAKE_LATEST then
      if not _threads[threadIndex].Finished then
        _threads[threadIndex].forceFinish;
        
  end;

  //create thread
  setlength(_threads, succ(length(_threads)));
  _threads[high(_threads)] := TCallbackThread.Create(saga.key, saga.callback(), args);

  result := _threads[high(_threads)].ThreadID;

  //start thread
  _threads[high(_threads)].Resume;
end;

procedure TThreadHandler.cleanup(hard: boolean = false);
var
  i: Integer;
  newThreads: PCallbackThreadArray;
begin
  setlength(newThreads, 0);

  if hard then
    for i := low(_threads) to high(_threads) do
    begin
      if _threads[i].Finished then continue;
      _threads[i].forceFinish;
    end;

  for i := low(_threads) to high(_threads) do
  begin
    if not _threads[i].Finished then
    begin
      setlength(newThreads, length(newThreads) + 1);
      newThreads[high(newThreads)] := @_threads[i];
    end;
  end;

  for i := 0 to high(newThreads) do
  begin
    _threads[i] := newThreads[i]^;
  end;
  setlength(_threads, length(newThreads));
end;

end.
