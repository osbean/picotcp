/*********************************************************************
PicoTCP. Copyright (c) 2012 TASS Belgium NV. Some rights reserved.
See LICENSE and COPYING for usage.
Do not redistribute without a written permission by the Copyright
holders.
  
Authors: Kristof Roelants, Simon Maes, Brecht Van Cauwenberghe
*********************************************************************/

#ifndef _INCLUDE_PICO_NAT
#define _INCLUDE_PICO_NAT
#include "pico_frame.h"

#define PICO_DEL_FLAGS_FIN_FORWARD   (0x8000)
#define PICO_DEL_FLAGS_FIN_BACKWARD  (0x4000)
#define PICO_DEL_FLAGS_SYN           (0x2000)
#define PICO_DEL_FLAGS_RST           (0x1000)


#ifdef PICO_SUPPORT_NAT
void pico_ipv4_nat_print_table(void);
int pico_ipv4_nat_add(uint32_t private_addr, uint16_t private_port, uint8_t proto, uint32_t nat_addr, uint16_t nat_port);
int pico_ipv4_nat_del(uint8_t proto, uint16_t nat_port);
int pico_ipv4_nat_find(uint32_t private_addr, uint16_t private_port, uint8_t proto, uint16_t nat_port);

int pico_ipv4_nat(struct pico_frame* f, struct pico_ip4 nat_addr);
int pico_ipv4_nat_enable(struct pico_ipv4_link *link);
int pico_ipv4_nat_isenabled_out(struct pico_ipv4_link *link);
int pico_ipv4_nat_isenabled_in(struct pico_frame *f);

#else

static inline int pico_ipv4_nat_isenabled_out(struct pico_ipv4_link *link)
{
  pico_err = PICO_ERR_EPROTONOSUPPORT;
  return -1;
}
static inline int pico_ipv4_nat_isenabled_in(struct pico_frame *f)
{
  pico_err = PICO_ERR_EPROTONOSUPPORT;
  return -1;
}

static inline int pico_ipv4_nat(struct pico_frame* f, struct pico_ip4 nat_addr)
{
  pico_err = PICO_ERR_EPROTONOSUPPORT;
  return -1;
}

static inline int pico_ipv4_nat_enable(struct pico_ipv4_link *link)
{
  pico_err = PICO_ERR_EPROTONOSUPPORT;
  return -1;
}

#define pico_ipv4_nat_print_table() do{}while(0)

static inline int pico_ipv4_nat_add(uint32_t private_addr, uint16_t private_port, uint8_t proto, uint32_t nat_addr, uint16_t nat_port)
{
  pico_err = PICO_ERR_EPROTONOSUPPORT;
  return -1;
}

static inline int pico_ipv4_nat_del(uint8_t proto, uint16_t nat_port)
{
  pico_err = PICO_ERR_EPROTONOSUPPORT;
  return -1;
}


static inline int pico_ipv4_nat_find(uint32_t private_addr, uint16_t private_port, uint8_t proto, uint16_t nat_port)
{
  pico_err = PICO_ERR_EPROTONOSUPPORT;
  return -1;
}

#endif

#endif /* _INCLUDE_PICO_NAT */
