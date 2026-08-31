program SampleProject;

uses
  Vcl.Forms,
  UnitRaylibSample in 'UnitRaylibSample.pas' {FormRaylibSample},
  uRaylibCustomThreadedBase in 'uRaylibCustomThreadedBase.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormRaylibSample, FormRaylibSample);
  Application.Run;
end.
