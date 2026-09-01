unit UnitRaylibSample;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  uRaylibCustomThreadedBase;

type
  TFormRaylibSample = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FRaylibView: TRaylibCustomThreadedBase;
    btnStart: TButton;
    btnStop: TButton;
    pnlUI: TPanel;
    tbFPS: TTrackBar;
    lblFPS: TLabel;
    FPSTimer: TTimer;
    procedure OnStartClick(Sender: TObject);
    procedure OnStopClick(Sender: TObject);
    procedure OnFPSTracking(Sender: TObject);
    procedure OnFPSTimer(Sender: TObject);
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
  Self.DoubleBuffered := True;

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

  // 4. Create FPS UI Panel (Hält Label und Trackbar zusammen sichtbar)
  pnlUI := TPanel.Create(Self);
  pnlUI.Parent := Self;
  pnlUI.Left := 390;
  pnlUI.Top := 5;
  pnlUI.Width := 270;
  pnlUI.Height := 65;
  pnlUI.BevelOuter := bvNone; // Unsichtbarer Rahmen
  pnlUI.Caption := '';
  pnlUI.DoubleBuffered := True; // WICHTIG: Sonst flackert die Trackbar
  // NEU: Z-Order nach vorne ziehen, damit es nicht von Raylib übermalt wird!
  pnlUI.BringToFront;

  // 5. Create FPS Label (Jetzt auf dem Panel)
  lblFPS := TLabel.Create(Self);
  lblFPS.Parent := pnlUI; // Parent ist jetzt das Panel!
  lblFPS.Caption := 'Target: 60 | Real: 0 FPS';
  lblFPS.Left := 10;
  lblFPS.Top := 5;
  lblFPS.Width := 200;
  lblFPS.Font.Size := 10;

  // 6. Create FPS TrackBar (Jetzt auf dem Panel)
  tbFPS := TTrackBar.Create(Self);
  tbFPS.Parent := pnlUI; // Parent ist jetzt das Panel!
  tbFPS.Min := 1;
  tbFPS.Max := 5000;
  tbFPS.Position := 60;
  tbFPS.Width := 250;
  tbFPS.Left := 10;
  tbFPS.Top := 25;
  tbFPS.OnChange := OnFPSTracking;

  // 7. Create FPS Update Timer
  FPSTimer := TTimer.Create(Self);
  FPSTimer.Interval := 500;
  FPSTimer.OnTimer := OnFPSTimer;
  FPSTimer.Enabled := True;
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


procedure TFormRaylibSample.OnFPSTracking(Sender: TObject);
begin
  if Assigned(FRaylibView) and Assigned(tbFPS) then
  begin
    FRaylibView.TargetFPS := Round(tbFPS.Position);
  end;
end;

procedure TFormRaylibSample.OnFPSTimer(Sender: TObject);
begin
  if Assigned(FRaylibView) and Assigned(lblFPS) then
  begin
    lblFPS.Caption := Format('Target: %d | Real: %d FPS', [FRaylibView.TargetFPS, FRaylibView.RealFPS]);
  end;
end;

end.
