unit Redux;

interface

  uses Typestuff, MutableObject;

  type

    TActionType = string;

    TAction = record
      key: TActionType;
      payload: TMutableObject;
    end;

    // TActionCreator = function(value: TMutableObject): TAction;

    TState = TMutableObject;

    TReducer = function(state: TState; action: TAction): TState;

    //TSubscribe = procedure(callback: TProcedure);

    //TDispatch = procedure(action: TAction);

    //TGetState = function: TState;

    TStore = class
      private
        __state: TState;
        __reducer: TReducer;
        __listeners: TCallbackArray;
      public
        function getState(): TState;
        procedure subscribe(callback: TCallback);
        procedure dispatch(action: TAction);
        constructor Create(initialState: TState; reducer: TReducer);
    end;

    //TODO: function makeCombinedStore(stores: array of stores): TStore;

var
  appStore: TStore;

implementation

constructor TStore.Create(initialState: TState; reducer: TReducer);
begin
  inherited Create;

  __state := initialState;
  __reducer := reducer;
end; 

function TStore.getState(): TState;
begin
  result := __state;
end;

procedure TStore.subscribe(callback: TCallback);
begin
  setlength(__listeners, length(__listeners) + 1);
  __listeners[high(__listeners)] := callback;
end;

procedure TStore.dispatch(action: TAction);
var
  i: Integer;
begin
  __reducer(getState(), action);

  //TODO: optimize with key<->listener dict
  for i := 0 to high(__listeners) do
  begin
    __listeners[i]();
  end;
end;

{
  Example / How to use:
  * Call makeExampleStore to create the store
  * Use getState() to query the store (make selectors for efficienty)
  * Use dispatch() to alter the store (make action records for efficienty)
  * Use subscribe() to pass callbacks that get called after dispatch


function makeExampleStoreState: TState;
begin
  result := TMutableObject.Create();
  result.assign('foo', 5);
  result.assign('bar', 'asd');
end; 

function setBarReducer(state: TState; action: TAction): TState;
begin
  result := state;
  result.assign('bar', action.payload.get('bar'));
end;

function setFooPlusFiveReducer(state: TState; action: TAction): TState;
begin
  result := state;
  result.assign('foo', action.payload.get('foo') + 5);
end;

function exampleStoreReducer(state: TState; action: TAction): TState;
begin
  result := state;

  if action.key = 'setFooPlusFive' then
    result := setFooPlusFiveReducer(state, action)
  else if action.key = 'setBar' then
    result := setBarReducer(state, action);

end;

function makeExampleStore: TStore;
begin
  result := TStore.Create(makeExampleStoreState(), exampleStoreReducer);
end;

}

end.

