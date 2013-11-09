This repository stores the current experiment code.

All of the IGOR experiment code is in the Procedures folder. The current procedures are:

* Camera.ipf - Camera GUI and utilities implementing the PCO camera XOP
* Config.ipf - 
* DDS_CMD.ipf - Utilities for interfacing with the Monroe Lab DDS boards
* Fitters.ipf - Currently only Poisson fit
* Init.ipf - Initializes global experiment variables
* PulseGUI.ipf - GUI for creating and running pulse sequences and analyzing the reesults
* SequencerControl.ipf - Utilities for interfacing with the Monroe Lab sequencer FPGA
* SetPoints.ipf - GUI for manually changing sequencer TTLs and DDS frequencies
* TrapVoltageControl.ipf - GUI and utilities interfacing with the NI PXI-6713 8-channel DAC boards
