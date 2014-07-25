#ifndef __webclient_h__
#define __webclient_h__



#include <xccompat.h>
#include "xtcp_client.h"

#ifdef __webclient_conf_h_exists__
#include "webclient_conf.h"
#endif



/** \struct server_config_t
 *  \brief  Web Server configuration
 */
typedef struct server_config_t_
{
  xtcp_ipaddr_t server_ip; /**<Server IP address */
  int tcp_in_port;         /**<TCP IN port */
  int tcp_out_port;        /**<TCP OUT port */
} server_config_t;


/*==========================================================================*/
/**
 *  Set server configuration. The webclient will look for this server and
 *  try connecting to it.
 *
 *  \param server_config    The IP address of the Server to connect to, IN
 *                          and OUT ports.
 *  \return None
 **/
void webclient_set_server_config(server_config_t server_config);

/*==========================================================================*/
/**
 *  Initialize web client.
 *
 *  \param c_xtcp    The XTCP channel
 *  \return None
 **/
void webclient_init(chanend c_xtcp);

/*==========================================================================*/
/**
 *  Connect to a web server.
 *
 *  \param c_xtcp    The XTCP channel
 *  \return None
 **/
void webclient_connect_to_server(chanend c_xtcp);

/*==========================================================================*/
/**
 *  Send data to web server.
 *
 *  \param c_xtcp    The XTCP channel
 *  \param data      Character array - data to send to web server
 *  \return 1 on success, 0 on failure.
 **/
int webclient_send_data(chanend c_xtcp, char data[]);

 /*==========================================================================*/
/**
 *  Close the current connection
 *
 *  \param c_xtcp    The XTCP channel
 *  \return None
 **/
void webclient_request_close(chanend c_xtcp);

#endif // __webclient_h__
