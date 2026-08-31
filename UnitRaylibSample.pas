unit UnitRaylibSample;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  uRaylibCustomThreadedBase;

type
  TFormRaylibSample = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FRaylibView: TRaylibCustomThreadedBase;
    btnStart: TButton;
    btnStop: TButton;
    btnToggleFPS: TButton;

    procedure OnStartClick(Sender: TObject);
    procedure OnStopClick(Sender: TObject);
    procedure OnToggleFPSClick(Sender: TObject);
  public
    { Public-Deklarationen }
  end;

var
  FormRaylibSample: TFormRaylibSample;

implementation

{$R *.dfm}

procedure TFormRaylibSample.FormCreate(Sender: TObject);
begin
  Caption := 'Raylib Custom Threaded Base Sample';
  ClientWidth := 800;
  ClientHeight := 600;

  // 1. Create the Custom Raylib Component
  FRaylibView := TRaylibCustomThreadedBase.Create(Self);
  FRaylibView.Parent := Self;
  FRaylibView.Align := alClient;
  FRaylibView.Margins.SetBounds(10, 50, 10, 10);
  FRaylibView.Active := False;

  // 2. Create Start Button
  btnStart := TButton.Create(Self);
  btnStart.Parent := Self;
  btnStart.Caption := 'Start Animation';
  btnStart.Width := 120;
  btnStart.Left := 20;
  btnStart.Top := 10;
  btnStart.OnClick := OnStartClick;

  // 3. Create Stop Button
  btnStop := TButton.Create(Self);
  btnStop.Parent := Self;
  btnStop.Caption := 'Stop Animation';
  btnStop.Width := 120;
  btnStop.Left := 150;
  btnStop.Top := 10;
  btnStop.OnClick := OnStopClick;

  // 4. Create Toggle FPS Button
  btnToggleFPS := TButton.Create(Self);
  btnToggleFPS.Parent := Self;
  btnToggleFPS.Caption := 'Toggle 30/120 FPS';
  btnToggleFPS.Width := 140;
  btnToggleFPS.Left := 280;
  btnToggleFPS.Top := 10;
  btnToggleFPS.OnClick := OnToggleFPSClick;
end;

procedure TFormRaylibSample.FormDestroy(Sender: TObject);
begin
  // Owned components are freed automatically
end;

procedure TFormRaylibSample.OnStartClick(Sender: TObject);
begin
  if Assigned(FRaylibView) then
    FRaylibView.Active := True;
end;

procedure TFormRaylibSample.OnStopClick(Sender: TObject);
begin
  if Assigned(FRaylibView) then
    FRaylibView.Active := False;
end;

procedure TFormRaylibSample.OnToggleFPSClick(Sender: TObject);
begin
  if Assigned(FRaylibView) then
  begin
    if FRaylibView.TargetFPS = 60 then
      FRaylibView.TargetFPS := 120
    else if FRaylibView.TargetFPS = 120 then
      FRaylibView.TargetFPS := 30
    else
      FRaylibView.TargetFPS := 60;

    if Assigned(btnToggleFPS) then
      btnToggleFPS.Caption := 'FPS: ' + IntToStr(FRaylibView.TargetFPS);
  end;
end;

end.
