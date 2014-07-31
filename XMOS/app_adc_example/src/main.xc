//#include <xs1.h>
//#include <platform.h>
#include <print.h>
#include <xscope.h>
#include <stdlib.h>
#include "startkit_gpio.h"
#include "startkit_adc.h"
#include "webclient.h"
#include "ethernet_board_support.h"
#include <stdio.h>
#include <timer.h>

typedef struct client_data_t {
  unsigned btn_press_count;
} client_data_t;

#define LOOP_PERIOD     20000000    //Trigger ADC and print results every 200ms
#define AWAKE_MILLISECS 60000
#define SLEEP_MILLISECS 30000

on ETHERNET_DEFAULT_TILE: ethernet_xtcp_ports_t xtcp_ports = {
  OTP_PORTS_INITIALIZER,
  ETHERNET_DEFAULT_SMI_INIT,
  ETHERNET_DEFAULT_MII_INIT_lite,
  ETHERNET_DEFAULT_RESET_INTERFACE_INIT
};

xtcp_ipconfig_t client_ipconfig = {
  {0, 0, 0, 0},
  {0, 0, 0, 0},
  {0, 0, 0, 0}
};

server_config_t server_config = {
  {192,168,0,4},
  3000 ,
  3000
};

client_data_t client_data = { 0 };

char ws_data_sleep[] = "Going to sleep.\n";
char ws_data_notify[] = "Program running! Sensor events will now be recorded.\n";
char ws_data_wake[] = "Button = bbb; Temperature = ttt; Joystick X = xxx, Y = yyy\n";
char ws_data_node[] = "http://localhost:3000/vehicleList";

void test_app(chanend c_xtcp){

  timer tmr;
  unsigned int sys_start_time, alarm_time;
//  sensor_data_t sensor_data;
  char fresh_start = 1;

  // Delay for some time to start web server on the host computer
  if(fresh_start) delay_seconds(2);
  // Set webserver parameters
  webclient_set_server_config(server_config);
  // Initialize web client
  webclient_init(c_xtcp);
  // Connect to webserver
  webclient_connect_to_server(c_xtcp);
  // Send notification to begin recording sensor datasd
  webclient_send_data(c_xtcp, ws_data_notify);
  // Connected to server. The sensor handler can now begin to record data.
//  c_sensor <: 1;
  tmr :> sys_start_time;
  int i=0;
  while(1)
  {
    select
    {
      case tmr when timerafter(sys_start_time + (AWAKE_MILLISECS * 100000)) :> void:
      {
        // Inform webserver that I am going to sleep
        webclient_send_data(c_xtcp, ws_data_sleep);
        // Close connection
        webclient_request_close(c_xtcp);
        break;
      }
      default:
          webclient_send_data(c_xtcp, ws_data_node);
          break;
    } //select
  } //while(1)
}

void read_adc(chanend c_xtcp){

}

//startkit_gpio_ports gpio_ports = {XS1_PORT_32A, XS1_PORT_4A, XS1_PORT_4B, XS1_CLKBLK_1}; //LEDs/SW, sliders, clock


void app(client startkit_led_if i_leds, client startkit_button_if i_button, client startkit_adc_if i_adc)
{
  timer t_loop;                 //Loop timer
  int loop_time;                //Loop time comparison variable

  unsigned short adc_val[4] = {0, 0, 0, 0};//ADC vals

  printstrln("App started");

  t_loop :> loop_time;          //Take the initial timestamp of the 100Mhz timer
  loop_time += LOOP_PERIOD;     //Set comparison to future time
  while (1) {
    select {

    case i_button.changed():    //Button event
      if (i_button.get_value() == BUTTON_DOWN) {
          printstrln("Button pressed!");
          i_leds.set(2, 2, LED_ON);
          i_leds.set(1, 2, LED_ON);
          i_leds.set(0, 2, LED_ON);
      }
      else {
          printstrln("Button released!");
          i_leds.set(2, 2, LED_OFF);
          i_leds.set(1, 2, LED_OFF);
          i_leds.set(0, 2, LED_OFF);
      }
      break;
                                //Loop timeout event
    case t_loop when timerafter(loop_time) :> void:
      i_adc.trigger();          //Fire the ADC!
      loop_time += LOOP_PERIOD; //Setup future time event
      break;

    case i_adc.complete():      //Notification from ADC server when aquisition complete
      i_adc.read(adc_val);      //Get the values (and clear the notfication)
      for(int i = 0; i < 4; i++){
        printstr("ADC chan ");
        printint(i);
        printstr(" = ");
        printint(adc_val[i]);
        if (i < 3) printstr(", ");
        switch (i){             //Map ADC channels to align with LEDs on startKIT
          case 0:
            i_leds.set(1, 1, adc_val[i]);
            break;
          case 1:
            i_leds.set(2, 0, adc_val[i]);
            break;
          case 2:
            i_leds.set(0, 1, adc_val[i]);
            break;
          case 3:
            i_leds.set(1, 0, adc_val[i]);
            break;
          }
        }
      printchar('\n');
      break;
    }//select
  }//while 1
}


int main()
{
  // These interface connections link the application to the GPIO task and ADC driver task
  startkit_led_if i_led;                                     //For setting LEDs
  startkit_button_if i_button;                               //For reading the button
  startkit_adc_if i_adc;                                     //For triggering/reading ADC
  chan c_adc;                                                //Used by ADC driver to connect to ADC hardware
  chan c_xtcp[1], c_sensor;
  par {
//    on tile[0].core[0]: startkit_gpio_driver(i_led, i_button,//Run GPIO task for leds/button
//                                             null, null,
//                                             gpio_ports);
    on tile[0].core[0]: adc_task(i_adc, c_adc, 0);           //Run ADC server task (on same core as GPIO!)
    startkit_adc(c_adc);                                     //Declare the ADC service (this is the ADC hardware, not a task)
    on tile[0]: app(i_led, i_button, i_adc);                 //Run the app
    on ETHERNET_DEFAULT_TILE: ethernet_xtcp_server(xtcp_ports, client_ipconfig, c_xtcp, 1);
    on tile[0]: test_app(c_xtcp[0]);
  }
  return 0;
}

