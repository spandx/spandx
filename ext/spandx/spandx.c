#include "spandx.h"

VALUE rb_mSpandx;
VALUE rb_mCore;
VALUE rb_mCsvParser;

static VALUE parse(VALUE self, VALUE line)
{
  VALUE items = rb_ary_new2(3);
  const char *line_ptr = RSTRING_PTR(line);
  int length = (int) RSTRING_LEN(line);
  char current_value[length];
  int current_value_length = 0;
  char current_charactor;
  enum {open, closed} state;
  state = open;
  int items_in_array = 0;

  for (int i = 1; i < length; i++) {
    current_charactor = line_ptr[i];

    switch(current_charactor) {
      case '"':
        if (state == closed) {
          state = open;
        } else {
          rb_ary_push(items, rb_str_new(current_value, current_value_length));
          items_in_array++;
          if (items_in_array == 3) return items;

          current_value_length = 0;
          state = closed;
        }
        break;
      case ',':
        if (state == open)
          current_value[current_value_length++] = current_charactor;
        break;
      default:
        current_value[current_value_length++] = current_charactor;
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
