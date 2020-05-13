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
  const VALUE items = rb_ary_new2(3);
  const char *p, *s, *t;
  const int line_length = RSTRING_LEN(line);
  enum { open, closed } state = closed;

  p = RSTRING_PTR(line);

  if (*p != '"') return Qnil;

  for (int i = 0; i < line_length; i++) {
    switch(*p) {
      case '"':
        if (state == closed) {
          state = open;
          p++;
          s = p;
        } else {
          t = p;
          t++;
          if (!*t || *t == 10 || *t == 13 || *t == ',') {
            rb_ary_push(items, rb_str_new(s, p - s));
            p = t;
            state = closed;
          }
        }
        break;
      default:
        p++;
        break;
    }
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
