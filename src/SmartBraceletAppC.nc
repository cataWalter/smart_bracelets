configuration SmartBraceletAppC {}

implementation {
  components MainC, SmartBraceletC as App;
  
  components new AMSenderC(8);
  components new AMReceiverC(8);
  components ActiveMessageC as RadioAM;
  
  components new TimerMilliC() as TimerPairing;
  components new TimerMilliC() as TimerStatus;

  components RandomC;
  
  // Boot interface
  App.Boot -> MainC.Boot;
  
  // Radio interface
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.AMControl -> RadioAM;
  
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;

  // Timers
  App.TimerPairing -> TimerPairing;
  App.TimerStatus -> TimerStatus;
  
  App.Random -> RandomC;
  RandomC <- MainC.SoftwareInit;
}


