#define RECORDING "nutrenke3" //This is the filename of your recording without the extension.
#define RECORDING_TYPE 1 //1 for in vehicle and 2 for on foot.

#include <a_npc>
main(){}

#if RECORDING_TYPE == 1
  public OnNPCEnterVehicle(vehicleid, seatid) StartRecordingPlayback(RECORDING_TYPE, RECORDING);
  public OnNPCExitVehicle() StopRecordingPlayback();
#endif