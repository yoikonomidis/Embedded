#include "webclient.h"
#include <xs1.h>
#include <string.h>
#include <print.h>
#include <timer.h>


server_config_t server_cfg;
xtcp_connection_t conn;



/*==========================================================================*/
/**
 *  Send data to the webserver.
 *
 *  \param c_xtcp   channel XTCP
 *  \param buf      character array containing data
 *  \param len      data length
 *  \return         1 for success, 0 for failure
 **/
static int webclient_send(chanend c_xtcp, unsigned char buf[], int len)
{
  int finished = 0;
  int success = 1;
  int index = 0, prev = 0;
  int id = conn.id;

  xtcp_init_send(c_xtcp, conn);

  while(!finished)
  {
    slave xtcp_event(c_xtcp, conn);

    switch(conn.event)
    {
      case XTCP_NEW_CONNECTION: xtcp_close(c_xtcp, conn); break;
      case XTCP_REQUEST_DATA:
      case XTCP_SENT_DATA:
      {
        int sendlen = (len - index);
        if (sendlen > conn.mss) sendlen = conn.mss;
        xtcp_sendi(c_xtcp, buf, index, sendlen);
        prev = index;
        index += sendlen;
        if (sendlen == 0)
        {
          finished = 1;
        }
        break;
      }

      case XTCP_RESEND_DATA: xtcp_sendi(c_xtcp, buf, prev, (index-prev)); break;
      case XTCP_RECV_DATA:
      {
        slave
        {
          c_xtcp <: 0;
        } // delay packet receive

        if (prev != len)
        success = 0;
        finished = 1;
        break;
      }
      case XTCP_TIMED_OUT:
      case XTCP_ABORTED:
      case XTCP_CLOSED:
      {
        if (conn.id == id)
        {
          finished = 1;
          success = 0;
        }
        break;
      }
      case XTCP_IFDOWN:
      {
        finished = 1;
        success = 0;
        break;
      }
    }
  }
  return success;
}

/*---------------------------------------------------------------------------
 webclient_set_server_config
 ---------------------------------------------------------------------------*/
void webclient_set_server_config(server_config_t server_config)
{
  server_cfg.server_ip[0] = server_config.server_ip[0];
  server_cfg.server_ip[1] = server_config.server_ip[1];
  server_cfg.server_ip[2] = server_config.server_ip[2];
  server_cfg.server_ip[3] = server_config.server_ip[3];
  server_cfg.tcp_in_port = server_config.tcp_in_port;
  server_cfg.tcp_out_port = server_config.tcp_out_port;
}

/*---------------------------------------------------------------------------
 webclient_init
 ---------------------------------------------------------------------------*/
void webclient_init(chanend c_xtcp)
{
  xtcp_ipconfig_t ipconfig;

  conn.event = XTCP_ALREADY_HANDLED;
  do
  {
    slave xtcp_event(c_xtcp, conn);
  } while(conn.event != XTCP_IFUP);

  xtcp_get_ipconfig(c_xtcp, ipconfig);
  printstr("IP Address: ");
  printint(ipconfig.ipaddr[0]);printstr(".");
  printint(ipconfig.ipaddr[1]);printstr(".");
  printint(ipconfig.ipaddr[2]);printstr(".");
  printint(ipconfig.ipaddr[3]);printstr("\n");
}

/*---------------------------------------------------------------------------
 webclient_connect_to_server
 ---------------------------------------------------------------------------*/
void webclient_connect_to_server(chanend c_xtcp)
{
  xtcp_listen(c_xtcp, server_cfg.tcp_in_port, XTCP_PROTOCOL_TCP);
  xtcp_connect(c_xtcp, server_cfg.tcp_out_port, server_cfg.server_ip, XTCP_PROTOCOL_TCP);

  conn.event = XTCP_ALREADY_HANDLED;
  do
  {
    slave xtcp_event(c_xtcp, conn);
//      conn.event = XTCP_NEW_CONNECTION;
  } while(conn.event != XTCP_NEW_CONNECTION);

}

/*---------------------------------------------------------------------------
 webclient_send_data
 ---------------------------------------------------------------------------*/
int webclient_send_data(chanend c_xtcp, char data[])
{
  return webclient_send(c_xtcp, data, strlen(data));
}

/*---------------------------------------------------------------------------
 webclient_request_close
 ---------------------------------------------------------------------------*/
void webclient_request_close(chanend c_xtcp)
{
  char dummy_data[1];
  webclient_send(c_xtcp, dummy_data, 0);
  xtcp_close(c_xtcp, conn);

  // Wait till the connection is closed
  conn.event = XTCP_ALREADY_HANDLED;
  do
  {
    slave xtcp_event(c_xtcp, conn);
  } while(conn.event != XTCP_CLOSED);
  // Ack the FIN,ACK from host. Let it close.
  delay_milliseconds(100);
}
