# RaylibCustomThreadedBase
A high-performance, threaded Delphi component that seamlessly embeds Raylib into VCL/FMX applications without blocking the UI thread.
    
**RaylibCustomThreadedBase v0.1**  
     
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/LaMitaOne/RaylibCustomThreadedBase)    
      
<img width="897" height="720" alt="Unbenannt" src="https://github.com/user-attachments/assets/421616c7-2f3b-44ef-9ad6-480d8e9a1c2f" />
     
This base class provides a robust, drop-in architecture for running Raylib game loops entirely in the background, making it perfect for creating complex visualizations, editors, or interactive 3D tools directly inside Delphi.    
     
Key Features:     
  
     Threaded Architecture: Separates the entire Raylib Game Loop (Initialization, Logic, Rendering, Shutdown) from the UI thread. The application remains 100% responsive even under heavy GPU load.
     Non-Blocking UI: The main thread never stalls. Raylib's native window is safely parented and embedded into a standard TWinControl (VCL/FMX).
     Precise QPC Frame Pacing: Utilizes QueryPerformanceCounter (via TStopwatch) to calculate absolute frame deadlines. Render time is automatically subtracted, so high target FPS values (120+) are actually reached.
     Hybrid Sleep/SpinWait: Uses a two-phase wait strategy (Sleep for the bulk of the frame, busy-spin the last ~2ms) to guarantee frame-exact timing without burning unnecessary CPU cycles.
     Windows Timer Resolution: Automatically requests timeBeginPeriod(1) on Windows to bypass the default ~15.6ms sleep granularity.
     Delta Time Updates: Logic updates use real measured delta times with safety clamping (prevents huge jumps after debugger pauses or stalls).
     Drift Correction: If the loop falls behind by more than 1 second, it resyncs to "now" instead of rushing a burst of frames to catch up.
     Clean Shutdown: Uses real TThread.WaitFor instead of hardcoded sleeps for a safe and immediate teardown of Raylib resources.
      
Sample exe and project included    
     
The repository includes a ready-to-run "Flying Cube" demo that shows:   
    
     How to inherit from TRaylibCustomThreadedBase.
     How to override UpdateLogic (3D physics/math).
     How to override RenderEffect (Raylib drawing calls).
     Dynamic resizing of the embedded Raylib viewport.
     UI controls to Start/Stop the loop and toggle FPS on the fly.
     
Technical Requirements:    
     Delphi (VCL or FMX)    
     Raylib for Delphi (or equivalent Raylib Pascal bindings)    
     Windows (due to Winapi.Windows usage for window parenting, though the QPC timer logic is cross-platform capable)    
     
