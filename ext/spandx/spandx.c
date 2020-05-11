#include "spandx.h"

VALUE rb_mSpandx;

void Init_spandx(void)
{
  rb_mSpandx = rb_define_module("Spandx");
}
