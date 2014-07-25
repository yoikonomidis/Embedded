#ifndef __ethernet_board_defaults_h__
#define __ethernet_board_defaults_h__

#ifdef __ethernet_conf_h_exists_
#include "ethernet_conf.h"
#endif

#define ETHERNET_DEFAULT_PHY_ADDRESS 0

// This file will set the various port defines depending on which slot the
// ethernet slice is connected to

#define ETHERNET_DEFAULT_TILE tile[0]
#define PORT_ETH_RXCLK on tile[0]: XS1_PORT_1J
#define PORT_ETH_RXD on tile[0]: XS1_PORT_4C
#define PORT_ETH_TXD on tile[0]: XS1_PORT_4D
#define PORT_ETH_RXDV on tile[0]: XS1_PORT_1K
#define PORT_ETH_TXEN on tile[0]: XS1_PORT_1L
#define PORT_ETH_TXCLK on tile[0]: XS1_PORT_1I
#define PORT_ETH_MDIO on tile[0]: XS1_PORT_1M
#define PORT_ETH_MDC on tile[0]: XS1_PORT_1N
#define PORT_ETH_INT on tile[0]: XS1_PORT_1O
#define PORT_ETH_ERR on tile[0]: XS1_PORT_1P


#endif // __ethernet_board_defaults_h__
