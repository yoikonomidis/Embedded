#include "webclient.h"
#include "ethernet_board_support.h"
#include "xtcp.h"
#include <stdio.h>
#include <timer.h>

typedef struct client_data_t {
  unsigned btn_press_count;
} client_data_t;

#define AWAKE_MILLISECS 60000
#define SLEEP_MILLISECS 30000

on tile[0]: in port p_sw1 = XS1_PORT_1A;

on ETHERNET_DEFAULT_TILE: ethernet_xtcp_ports_t xtcp_ports = {
  OTP_PORTS_INITIALIZER,
  ETHERNET_DEFAULT_SMI_INIT,
  ETHERNET_DEFAULT_MII_INIT_lite,
  ETHERNET_DEFAULT_RESET_INTERFACE_INIT
};

xtcp_ipconfig_t client_ipconfig = {
//  {192,168,2,99},
//  {255,255,255,0},
//  {192, 168, 2, 254}
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
  printf("Step 1\n");
  // Initialize web client
  webclient_init(c_xtcp);
  printf("Step 2\n");
  // Connect to webserver
  webclient_connect_to_server(c_xtcp);
  printf("Step 3\n");
  // Send notification to begin recording sensor datasd
  webclient_send_data(c_xtcp, ws_data_notify);
  printf("Step 4\n");
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
void test_app2(chanend c_xtcp){

}

/*---------------------------------------------------------------------------
 main
 ---------------------------------------------------------------------------*/
int main(void)
{
  chan c_xtcp[1], c_adc, c_sensor;

  par
  {
    on ETHERNET_DEFAULT_TILE: ethernet_xtcp_server(xtcp_ports, client_ipconfig, c_xtcp, 1);
//    on tile[0]: ethernet_sleep_wake_handler(c_sensor, c_xtcp[0]);
    on tile[0]: test_app(c_xtcp[0]);
//    on tile[0] :test_app2(c_xtcp[0]);
//    on tile[0]: mixed_signal_slice_sensor_handler(c_sensor, c_adc, trigger_port, p_sw1);
//    xs1_a_adc_service(c_adc);
  } // par
  return 0;
}
