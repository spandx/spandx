#include "spandx.h"

VALUE rb_mSpandx;
VALUE rb_mCore;
VALUE rb_mCsvParser;

static VALUE parse(VALUE self, VALUE line)
{
  const char *ptr = RSTRING_PTR(line);
  int length = RSTRING_LEN(line);
  int indexes[6];
  int k = 0;

  for (int i = 0; i < length; i++) {
    if (ptr[i] == '"')
      indexes[k++] = i;

    if (k > 6) return Qnil;
  }

  VALUE items = rb_ary_new2(sizeof(indexes) / 2);

  int start = 0;
  for (int i = 0, j = 1; i < k; i += 2, j=i+1) {
    if (indexes[i] + 1 == indexes[j]) {
      rb_ary_push(items, rb_str_new_cstr(""));
    } else {
      start = indexes[i] + 1;
      rb_ary_push(items, rb_str_substr(line, start, indexes[j] - start));
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
