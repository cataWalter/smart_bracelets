#include "Timer.h"
#include "SmartBracelet.h"
#include <stdio.h>
#include <time.h>



#define KEYone "f7cgqmLb9apmQCmEU2xv"
#define KEYtwo "Q3KyyzejJqmHIMbzGx44"
#define BDCAST 101
#define PAIRING 1
#define STATUS 2
#define PFOUND 3
#define STANDING 5
#define WALKING 6
#define RUNNING 7
#define FALLING 8

#define SELF TOS_NODE_ID

module SmartBraceletC @safe() {
  uses {
    interface Boot;
    
    interface Random;
    interface AMSend;
    interface Receive;
    interface SplitControl as AMControl;
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements;
    
    interface Timer<TMilli> as TimerPairing;
    interface Timer<TMilli> as TimerStatus;
}
}

implementation {
  // VARIABLES 
	uint8_t key[20];
	message_t packet;
	uint16_t paired_addr = -1;
	bool isChild = 0;
	bool pairing = 0;
	int i;
	uint8_t last_x = -1;
	uint8_t last_y = -1;
	
	task void sendFound();
	task void sendPairing();
	task void sendStatus();
	
	
  // Start
  event void Boot.booted() {
  
  	// Seed RNG
  	srand(time(NULL)*SELF);
  
  	// Load Key & Boot, then call radio to turn on
  	if (SELF < 3)for (i=0; i<20; i++)key[i] = KEYone[i];
  	else for (i=0; i<20; i++)key[i] = KEYtwo[i];
  	if (SELF % 2 == 1) isChild = 1;
  	dbg("Boot", "Started node %u with key ", SELF);
  	for(i=0;i<20;i++)dbg_clear("Boot", "%c", key[i]);
  	dbg_clear("Boot", ".\n");
  	call AMControl.start();
  }

  // Turn on Radio then go to Pairing
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      dbg("Radio", "Node's Radio ready\n");
      dbg("Pairing", "Pairing phase started\n");
      
      pairing = 1;
      call TimerPairing.startPeriodic(250);
    } else {
      call AMControl.start();
    }
  }
  
  event void AMControl.stopDone(error_t err) {
  	;
  }
  
  // Periodic Pairing request sender
  event void TimerPairing.fired() {
  	post sendPairing();
  }
  
  // Radio errors handler
  event void AMSend.sendDone(message_t* buf, error_t error) {
    if (&packet == buf && error == SUCCESS) {
    }
    else{
      dbgerror("Radio", "Error in sending\n");
    }
  }
  
  // Inbox messages handler
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    msggtype* dat = (msggtype*)payload;
    dbg("Radio", "Received message of type %d from source %d\n", dat->type, dat->source);
    
    // Control destination, if not meant for self discard
    if(dat->dest == SELF || dat->dest == BDCAST){
   		if(dat->type == PAIRING){
   			// If key is different, discard and wait
    		for (i=0; i<20; i++)if(dat->key[i] != key[i]){
    			dbg("Radio", "...message discarded\n");
    			return msg;
    		}
    		// If key is correct, send notice to sender and remember address	
    		paired_addr = dat->source;
   			post sendFound();
    	}
    	else if(dat->type == PFOUND && pairing) {
    		// If key is wrong, discard
    		for (i=0; i<20; i++)if(dat->key[i] != key[i]){
    			dbg("Radio", "...message discarded\n");
    			return msg;
    		}
    		// If key is correct, stop pairing and start sending status
    		dbg("Pairing", "Pairing stopped on FOUND received\n");
    		pairing = 0;
    		call TimerPairing.stop();
    		if(isChild) call TimerStatus.startPeriodic(10000);
    		// Parent has timer for missing child
    		else call TimerStatus.startOneShot(60000);
    	}
    	else if(dat->type == STATUS){
    		// If a status message is received, reset "missing" timer and display status
    		dbg("Radio", "Status Received %d @ %d,%d\n", dat->status, dat->x, dat->y);
    		call TimerStatus.stop();
    		call TimerStatus.startOneShot(60000);
    		last_x = dat->x;
    		last_y = dat->y;
    		if(dat->status == FALLING) dbg("ALARM", "! - FALLING - ! @%d,%d\n", dat->x, dat->y);
    	}
    }
    return msg;
  }


  // Periodic Status poster, or if parent "missing" child tracker
  event void TimerStatus.fired(){
 	 if(isChild) post sendStatus();
 	 else dbg("ALARM", "! - MISSING - ! --------- last found @%d,%d\n", last_x, last_y);
 }
 
 // Prepare and send "stop pairing" message
 task void sendFound(){
 	msggtype* msgg = (msggtype*) call Packet.getPayload(&packet, sizeof(msggtype));
 	for (i=0; i<20; i++)msgg->key[i] = key[i];
 	msgg->source = SELF;
   	msgg->dest = paired_addr;
   	msgg->type = PFOUND;
   	dbg("Pairing", "sending FOUND to %d\n",msgg->dest);
 	call AMSend.send(paired_addr, &packet, sizeof(msggtype));
 }
 
 // Prepare and send pairing request to broadcast
 task void sendPairing(){
 	msggtype* msgg = (msggtype*) call Packet.getPayload(&packet, sizeof(msggtype));
 	for (i=0; i<20; i++)msgg->key[i] = key[i];
 	msgg->source = SELF;
   	msgg->dest = BDCAST;
   	msgg->type = PAIRING;
   	dbg("Pairing", "sending Pairing broadcast request\n");
 	call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(msggtype));
 }
 
 // Prepare and send status update
 task void sendStatus(){
 	msggtype* msgg = (msggtype*) call Packet.getPayload(&packet, sizeof(msggtype));
 	for (i=0; i<20; i++)msgg->key[i] = key[i];
 	msgg->source = SELF;
   	msgg->dest = paired_addr;
   	msgg->type = STATUS;
   	
   	i = rand()%10;
   	
   	if(i<3) msgg->status = STANDING;
   	else if(i<6) msgg->status = WALKING;
   	else if(i<9) msgg->status = RUNNING;
   	else msgg->status = FALLING;
   	
   	msgg->x = rand()%100;
   	msgg->y = rand()%100;
   	
   	dbg("Radio", "Status: %d, x:%d y:%d\n", msgg->status, msgg->x, msgg->y);
 	call AMSend.send(paired_addr, &packet, sizeof(msggtype));
 }
 
  
}




