#include "simplefs.h"

#include "stdlib.h"

#include "web_server.h"

#ifdef __web_server_conf_h_exists__
#include "web_server_conf.h"
#endif

fs_dir_t _web = {NULL, NULL, NULL, {0}};

int web_server_dyn_expr(int exp, char *buf, int app_state, int connection_state)
{
  switch (exp) {
  }
  return 0;
}

fs_dir_t *root = &_web;

