#include "spandx.h"

VALUE rb_mSpandx;
VALUE rb_mCore;
VALUE rb_mCsvParser;

// "name","version","license"
// "name","version","license"\n
// "name","version","license"\r
// "name","version","license"\r\n
// "name","version",""\r\n
static VALUE parse(VALUE self, VALUE line)
{
  if (NIL_P(line)) return Qnil;

  char *p = RSTRING_PTR(line);
  if (*p != '"') return Qnil;

  const VALUE items = rb_ary_new2(3);
  const char *s, *n;
  const int len = RSTRING_LEN(line);
  enum { open, closed } state = closed;

  for (int i = 0; i < len && *p; i++) {
    if (*p == '"') {
      n = p;
      if (i < (len - 1)) *n++;

      if (state == closed) {
        s = n;
        state = open;
      } else if (state == open) {
        if (!*n || n == p || *n == ',' || *n == 10) {
          rb_ary_push(items, rb_str_new(s, p - s));
          state = closed;
        }
      }
    }
    *p++;
  }

  return items;
}

void Init_spandx(void)
{
  rb_mSpandx = rb_define_module("Spandx");
  rb_mCore = rb_define_module_under(rb_mSpandx, "Core");
  rb_mCsvParser = rb_define_module_under(rb_mCore, "CsvParser");
  rb_define_module_function(rb_mCsvParser, "parse", parse, 1);
}
