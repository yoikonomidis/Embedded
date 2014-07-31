#include "ms_sensor.h"
#include "analog_tile_support.h"



#define DEBOUNCE_INTERVAL       XS1_TIMER_HZ/50
#define BUTTON_1_PRESS_VALUE    0x1
#define ADC_TRIGGER_PERIOD      10000000 // 100ms for ADC trigger
#define TEMPERATURE_LUT_ENTRIES 16


// sensor data
static sensor_data_t sensor_data;
// The temperature look-up table to convert ADC value from Thermistor to Celsius
static int TEMPERATURE_LUT[TEMPERATURE_LUT_ENTRIES][2] =
{
  {-10,211},{-5,202},{0,192},{5,180},
  {10,167},{15,154},{20,140},{25,126},
  {30,113},{35,100},{40,88},{45,77},
  {50,250},{55,230},{60,210}
};



/*---------------------------------------------------------------------------
 convert ADC value to temperature in Celsius
 ---------------------------------------------------------------------------*/
static int celsius_temperature(int adc_value)
{
  int i = 0, x1, y1, x2, y2, celsius = 0;

  while((adc_value < TEMPERATURE_LUT[i][1]) && (i < TEMPERATURE_LUT_ENTRIES)) i++;

  if (i != TEMPERATURE_LUT_ENTRIES)
  {
    x1 = TEMPERATURE_LUT[i-1][1];
    y1 = TEMPERATURE_LUT[i-1][0];
    x2 = TEMPERATURE_LUT[i][1];
    y2 = TEMPERATURE_LUT[i][0];
    celsius = y1 + (((adc_value - x1) * (y2 - y1)) / (x2 - x1));
  }
  return celsius;
}

/*---------------------------------------------------------------------------
 simple filter
 ---------------------------------------------------------------------------*/
static unsigned char value_beyond_limits(int new_val, int old_val, int limit)
{
  if(new_val < (old_val - limit)) return 1;
  if(new_val > (old_val + limit)) return 1;
  return 0;
}

/*---------------------------------------------------------------------------
 Sensor data changed, return it.
 ---------------------------------------------------------------------------*/
void ms_sensor_data_changed(chanend c_sensor, sensor_data_t &sensor_data)
{
  c_sensor :> sensor_data;
}

/*---------------------------------------------------------------------------
 mixed_signal_slice_sensor_handler
 ---------------------------------------------------------------------------*/
void mixed_signal_slice_sensor_handler(chanend c_sensor,
                                       chanend c_adc,
                                       port trigger_port,
                                       in port p_sw1)
{
  unsigned data[3]; //Array for storing ADC results
  int scan_button_flag = 1;
  unsigned button_state_1 = 0;
  unsigned button_state_2 = 0;
  timer t_scan_button_flag, adc_trigger_timer;
  unsigned time, adc_trigger_time;


  sensor_data.btn_press_count = 0;
  sensor_data.joystick_x = 0;
  sensor_data.joystick_y = 0;
  sensor_data.temperature = 0;

  at_adc_config_t adc_config = { {0, 0, 0, 0, 0, 0, 0, 0}, 0, 0, 0}; //initialise all ADC to off

  adc_config.input_enable[1] = 1; //Input 1 is thermistor
  adc_config.input_enable[2] = 1; //Input 2 is horizontal axis of the joystick
  adc_config.input_enable[3] = 1; //Input 3 is vertical axis of the joystick

  adc_config.bits_per_sample = ADC_8_BPS;
  adc_config.samples_per_packet = 3; //Allow samples to be sent in one hit
  adc_config.calibration_mode = 0;

  at_adc_enable(adc_tile, c_adc, trigger_port, adc_config);
  at_adc_trigger_packet(trigger_port, adc_config); //Fire the ADC!

  set_port_drive_low(p_sw1);
  t_scan_button_flag :> time;
  p_sw1 :> button_state_1;

  adc_trigger_timer :> adc_trigger_time;         //Set timer for first loop tick
  adc_trigger_time += ADC_TRIGGER_PERIOD;

  // Wait till the Ethernet handler is ready
  c_sensor :> int _;

  while(1)
  {
    select
    {
      //::Button Scan Start
      case scan_button_flag => p_sw1 when pinsneq(button_state_1) :> button_state_1:
      {
        t_scan_button_flag :> time;
        scan_button_flag = 0;
        break;
      }
      case !scan_button_flag => t_scan_button_flag when timerafter(time + DEBOUNCE_INTERVAL) :> void:
      {
        p_sw1 :> button_state_2;
        if(button_state_1 == button_state_2)
        {
          if(button_state_1 == BUTTON_1_PRESS_VALUE)
          {
            sensor_data.btn_press_count++;
            c_sensor <: sensor_data;
          }
        }
        scan_button_flag = 1;
        break;
      }
      //::Button Scan End

      case adc_trigger_timer when timerafter(adc_trigger_time) :> adc_trigger_time:
      {
        at_adc_trigger_packet(trigger_port, adc_config);    //Trigger ADC
        adc_trigger_time += ADC_TRIGGER_PERIOD;
        break;
      } // case loop_timer to trigger ADC

      case at_adc_read_packet(c_adc, adc_config, data): //if data ready to be read from ADC
      {
        unsigned char ch_temp, ch_jx, ch_jy;

        ch_temp = value_beyond_limits(celsius_temperature(data[0]), sensor_data.temperature, 1);
        ch_jx = value_beyond_limits(data[1], sensor_data.joystick_x, 1);
        ch_jy = value_beyond_limits(data[2], sensor_data.joystick_y, 1);

        if(ch_temp || ch_jy || ch_jy)
        {
          sensor_data.temperature = celsius_temperature(data[0]); //First value in packet
          sensor_data.joystick_x  = data[1]; //Second value in packet
          sensor_data.joystick_y  = data[2]; //Third value in packet
          c_sensor <: sensor_data;
        }
        break;
      } // case at_adc_read_packet

    } // select
  } // while(1)
}
