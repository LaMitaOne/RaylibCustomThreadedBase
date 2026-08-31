{*******************************************************************************
  RaylibThreadedRenderer v0.1
********************************************************************************
  A high-performance, threaded VCL Raylib component.
  Utilizing Raylib for off-screen/native rendering embedded in VCL.

  Key Features:
  - Threaded Architecture: Separates Raylib Game Loop from the UI Thread.
  - Non-Blocking UI: Main thread remains responsive even at high load.
  - Precise Frame Pacing: QPC-based absolute frame deadlines with a hybrid
    Sleep/SpinWait strategy.

   Author: Lara Miriam Tamy Reschke / LamitaOne

*******************************************************************************}


unit uRaylibCustomThreadedBase;

interface

uses
  System.SysUtils, System.Types, System.Classes, System.Math,
  System.SyncObjs, System.Diagnostics,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  Winapi.Windows, Winapi.MMSystem,
  Raylib, rlgl, RayMath;

const
  SPIN_THRESHOLD_NS = 2000000; // 2 ms

type
  THighResTimer = record
    Frequency: Int64;
    procedure Init;
    function GetTicks: Int64; inline;
    procedure HybridWaitUntil(const ATargetTicks, ASpinNanoseconds: Int64);
  end;

  TRaylibCustomThreadedBase = class(TWinControl)
  private
    { Threading & Sync }
    FThread: TThread;
    FLock: TCriticalSection;
    FTargetFPS: Integer;
    FThreadActive: Boolean;
    FPaused: Boolean;
    FActive: Boolean;

    { Raylib State }
    FRaylibWnd: HWND;
    FInitialized: Boolean;
    FWindowName: String;

    { Demo Mode State }
    FCubePosition: TVector3;
    FCubeVelocity: TVector3;
    FAngle: Single;
    FCamera: TCamera3D;

    { Setters }
    procedure SetActive(const Value: Boolean);
    procedure SetTargetFPS(const Value: Integer);

    { Internal Thread Methods }
    procedure StartThread;
    procedure StopThread;
  protected
    procedure Resize; override;
    procedure CreateWindowHandle(const Params: TCreateParams); override;
    procedure DestroyWindowHandle; override;

    { Virtual Methods - Override these in your components }
    procedure InitRaylibResources; virtual;
    procedure UpdateLogic(const DeltaTime: Double); virtual;
    procedure RenderEffect(const ATime: Double); virtual;
    procedure ShutdownRaylibResources; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Align;
    property Anchors;
    property Visible;
    property Active: Boolean read FActive write SetActive default False;
    property TargetFPS: Integer read FTargetFPS write SetTargetFPS default 60;
  end;

implementation

{==============================================================================
  THighResTimer Implementation
==============================================================================}

procedure THighResTimer.Init;
begin
  Frequency := TStopwatch.Frequency;
end;

function THighResTimer.GetTicks: Int64;
begin
  Result := TStopwatch.GetTimestamp;
end;

procedure THighResTimer.HybridWaitUntil(const ATargetTicks, ASpinNanoseconds: Int64);
var
  SpinTicks, Remaining: Int64;
begin
  if Frequency = 0 then Exit;
  SpinTicks := (ASpinNanoseconds * Frequency) div 1000000000;

  Remaining := ATargetTicks - GetTicks;
  while Remaining > SpinTicks do
  begin
    Sleep(1);
    Remaining := ATargetTicks - GetTicks;
  end;
  while GetTicks < ATargetTicks do ;
end;

{==============================================================================
  TRaylibCustomThreadedBase
==============================================================================}

constructor TRaylibCustomThreadedBase.Create(AOwner: TComponent);
begin
  inherited;
  FLock := TCriticalSection.Create;
  FThreadActive := False;
  FPaused := True;
  FActive := False;
  FTargetFPS := 60;
  Width := 800;
  Height := 600;
  FWindowName := 'RaylibThreadedBase_' + IntToStr(IntPtr(Self));

  // Demo Mode Init
  FCubePosition := Vector3Create(0, 0, 0);
  FCubeVelocity := Vector3Create(3, 3, 3);
  FAngle := 0;

  FCamera.position := Vector3Create(10.0, 10.0, 10.0);
  FCamera.target := Vector3Create(0, 0, 0);
  FCamera.up := Vector3Create(0, 1, 0);
  FCamera.fovy := 45.0;
  FCamera.projection := CAMERA_PERSPECTIVE;
end;

destructor TRaylibCustomThreadedBase.Destroy;
begin
  StopThread;
  FreeAndNil(FLock);
  inherited;
end;

procedure TRaylibCustomThreadedBase.CreateWindowHandle(const Params: TCreateParams);
begin
  inherited;
end;

procedure TRaylibCustomThreadedBase.DestroyWindowHandle;
begin
  StopThread;
  inherited;
end;

procedure TRaylibCustomThreadedBase.Resize;
begin
  inherited;
  // Resize the embedded Raylib window
  if FInitialized and (FRaylibWnd <> 0) then
    SetWindowPos(FRaylibWnd, 0, 0, 0, ClientWidth, ClientHeight, SWP_NOZORDER or SWP_NOACTIVATE);
end;

procedure TRaylibCustomThreadedBase.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    if FActive then
    begin
      if not FThreadActive then
        StartThread;
      FPaused := False;
    end
    else
    begin
      FPaused := True;
    end;
  end;
end;

procedure TRaylibCustomThreadedBase.SetTargetFPS(const Value: Integer);
begin
  if FTargetFPS <> Value then
    FTargetFPS := Value;
end;

procedure TRaylibCustomThreadedBase.StartThread;
begin
  if FThreadActive then Exit;
  FThreadActive := True;

  // Ensure VCL handle is created BEFORE thread starts so we can parent Raylib to it
  if Self.Handle = 0 then
    Self.HandleNeeded;

  FThread := TThread.CreateAnonymousThread(
    procedure
    var
      Timer: THighResTimer;
      Freq, FrameTicks: Int64;
      NextFrame, NowTicks, LastFrameTicks: Int64;
      DeltaSec, TimeSec: Double;
    begin
      {$IFDEF MSWINDOWS}
      timeBeginPeriod(1);
      {$ENDIF}
      try
        // 1. RAYLIB INITIALIZATION (In Thread)
        SetConfigFlags(FLAG_MSAA_4X_HINT or FLAG_VSYNC_HINT);
        InitWindow(800, 600, PAnsiChar(AnsiString(FWindowName)));

        FRaylibWnd := FindWindowA(nil, PAnsiChar(AnsiString(FWindowName)));
        if (FRaylibWnd <> 0) and (Self.Handle <> 0) then
        begin
          Winapi.Windows.SetParent(FRaylibWnd, Self.Handle);
          SetWindowLong(FRaylibWnd, GWL_STYLE, WS_CHILD or WS_VISIBLE);
          SetWindowPos(FRaylibWnd, 0, 0, 0, Self.ClientWidth, Self.ClientHeight, SWP_NOZORDER or SWP_NOACTIVATE);
        end;

        // 2. Custom resource loading
        InitRaylibResources;

        FInitialized := True;

        // 3. Timer Init
        Timer.Init;
        Freq := Timer.Frequency;
        if Freq <= 0 then Freq := 10000000;

        NowTicks := Timer.GetTicks;
        LastFrameTicks := NowTicks;
        NextFrame := NowTicks;

        // 4. THREAD GAME LOOP
        while not TThread.CheckTerminated do
        begin
          if WindowShouldClose() then Break;

          // Measure Delta
          NowTicks := Timer.GetTicks;
          DeltaSec := (NowTicks - LastFrameTicks) / Freq;
          LastFrameTicks := NowTicks;

          if (DeltaSec <= 0) or (DeltaSec > 0.25) then
            DeltaSec := 1 / 60;

          // Update Logic
          if not FPaused then
            UpdateLogic(DeltaSec);

          // Render
          TimeSec := NowTicks / Freq;
          RenderEffect(TimeSec);

          // FPS PACING
          if FTargetFPS > 0 then
            FrameTicks := Round(Freq / FTargetFPS)
          else
            FrameTicks := Freq div 60;

          NextFrame := NextFrame + FrameTicks;

          // Drift correction
          NowTicks := Timer.GetTicks;
          if (NowTicks - NextFrame) > Freq then
            NextFrame := NowTicks;

          // Hybrid wait
          Timer.HybridWaitUntil(NextFrame, SPIN_THRESHOLD_NS);
        end;

      finally
        // 5. CLEANUP
        FInitialized := False;
        ShutdownRaylibResources;
        if FRaylibWnd <> 0 then
          CloseWindow();

        FThreadActive := False;
        {$IFDEF MSWINDOWS}
        timeEndPeriod(1);
        {$ENDIF}
      end;
    end);

  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

procedure TRaylibCustomThreadedBase.StopThread;
begin
  if not Assigned(FThread) then Exit;

  FThread.Terminate;
  FThread.WaitFor;
  FreeAndNil(FThread);
end;

{------------------------------------------------------------------------------
  VIRTUAL METHODS
------------------------------------------------------------------------------}

procedure TRaylibCustomThreadedBase.InitRaylibResources;
begin
  // Override to load textures, models, shaders
end;

procedure TRaylibCustomThreadedBase.ShutdownRaylibResources;
begin
  // Override to unload textures, models, shaders
end;

procedure TRaylibCustomThreadedBase.UpdateLogic(const DeltaTime: Double);
begin
  // 1. Move Cube
  FCubePosition.x := FCubePosition.x + FCubeVelocity.x * DeltaTime;
  FCubePosition.y := FCubePosition.y + FCubeVelocity.y * DeltaTime;
  FCubePosition.z := FCubePosition.z + FCubeVelocity.z * DeltaTime;

  // Bounce off invisible walls
  if Abs(FCubePosition.x) > 5 then FCubeVelocity.x := -FCubeVelocity.x;
  if Abs(FCubePosition.y) > 5 then FCubeVelocity.y := -FCubeVelocity.y;
  if Abs(FCubePosition.z) > 5 then FCubeVelocity.z := -FCubeVelocity.z;

  // Rotate
  FAngle := FAngle + (1.5 * DeltaTime);
end;

procedure TRaylibCustomThreadedBase.RenderEffect(const ATime: Double);
begin
  BeginDrawing();
  ClearBackground(RAYWHITE);

  BeginMode3D(FCamera);
    rlPushMatrix();
      rlTranslatef(FCubePosition.x, FCubePosition.y, FCubePosition.z);
      rlRotatef(FAngle * 57.2958, 1, 1, 0); // Convert rad to deg
      DrawCube(Vector3Create(0,0,0), 2.0, 2.0, 2.0, RED);
      DrawCubeWires(Vector3Create(0,0,0), 2.0, 2.0, 2.0, MAROON);
    rlPopMatrix();

    DrawGrid(20, 1.0);
  EndMode3D();

  DrawText(PAnsiChar('Raylib Threaded Base - Flying Cube'), 10, 10, 20, BLACK);

  EndDrawing();

  // Force VCL to redraw the hosted window area
  if FRaylibWnd <> 0 then
    RedrawWindow(FRaylibWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW);
end;

end.
